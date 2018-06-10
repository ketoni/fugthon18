#ifdef _WIN32
    #define WIN32_LEAN_AND_MEAN
    #include <windows.h>
#endif // _WIN32

#include <GL/gl3w.h>
#include <GLFW/glfw3.h>
#include <imgui.h>
#include <imgui_impl_glfw_gl3.h>
#include <iostream>
#include <math.h>
#include <memory>
#include <sstream>
#include <sync.h>
#include <track.h>

#include "audioStream.hpp"
#include "frameBuffer.hpp"
#include "gpuProfiler.hpp"
#include "logger.hpp"
#include "quad.hpp"
#include "scene.hpp"
#include "shaderProgram.hpp"
#include "timer.hpp"

// Comment out to disable autoplay without tcp-Rocket
//#define MUSIC_AUTOPLAY
// Comment out to load sync from files
#define TCPROCKET
// Comment out to remove gui
#define GUI

using std::cout;
using std::cerr;
using std::endl;

namespace {
    const static char* WINDOW_TITLE = "veipör";
    GLsizei XRES = 1920;
    GLsizei YRES = 1080;
    float LOGW = 690.f;
    float LOGH = 210.f;
    float LOGM = 10.f;
    GLfloat CURSOR_POS[] = {0.f, 0.f};
    bool RESIZED = true;
    std::vector<std::vector<GLfloat>> fft8Vecs(2, {8, 0});
}

//Set up audio callbacks for rocket
static struct sync_cb audioSync = {
    AudioStream::pauseStream,
    AudioStream::setStreamRow,
    AudioStream::isStreamPlaying
};

void keyCallback(GLFWwindow* window, int32_t key, int32_t scancode, int32_t action,
                 int32_t mods)
{
    if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS)
        glfwSetWindowShouldClose(window, GL_TRUE);
    else if (key == GLFW_KEY_O && action == GLFW_PRESS)
        AudioStream::getInstance().stop();
    else if (key == GLFW_KEY_P && action == GLFW_PRESS) {
        if (AudioStream::getInstance().isPlaying())
            AudioStream::getInstance().pause();
        else
            AudioStream::getInstance().play();
    }
#ifdef GUI
    else
        ImGui_ImplGlfwGL3_KeyCallback(window, key, scancode, action, mods);
#endif // GUI
}

void cursorCallback(GLFWwindow* window, double xpos, double ypos)
{
    if (glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_LEFT) == GLFW_PRESS) {
        CURSOR_POS[0] = 2 * xpos / XRES - 1.f;
        CURSOR_POS[1] = 2 * (YRES - ypos) / YRES - 1.f;
    }
}

void mouseButtonCallback(GLFWwindow* window, int button, int action, int mods)
{
#ifdef GUI
    if (ImGui::IsMouseHoveringAnyWindow()) {
        ImGui_ImplGlfwGL3_MouseButtonCallback(window, button, action, mods);
        return;
    }
#endif //GUI

    if (button == GLFW_MOUSE_BUTTON_LEFT && action == GLFW_PRESS) {
        double xpos, ypos;
        glfwGetCursorPos(window, &xpos, &ypos);
        CURSOR_POS[0] = 2 * xpos / XRES - 1.f;
        CURSOR_POS[1] = 2 * (YRES - ypos) / YRES - 1.f;
    }
}

void windowSizeCallback(GLFWwindow* window, int width, int height)
{
    (void) window;
    XRES = width;
    YRES = height;
    glViewport(0, 0, XRES, YRES);
    RESIZED = true;
}

static void errorCallback(int error, const char* description)
{
    cerr << "GLFW error " << error << ": " << description << endl;
}

#ifdef _WIN32
int APIENTRY WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR lpCmdLine, INT nCmdShow)
{
    (void) hInstance;
    (void) hPrevInstance;
    (void) lpCmdLine;
    (void) nCmdShow;
#else
int main()
{
#endif // _WIN32
    // Init GLFW-context
    glfwSetErrorCallback(errorCallback);
    if (!glfwInit()) exit(EXIT_FAILURE);

    // Set desired context hints
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

    // Create the window
    GLFWwindow* windowPtr;
    windowPtr = glfwCreateWindow(XRES, YRES, WINDOW_TITLE, NULL, NULL);
    //windowPtr = glfwCreateWindow(XRES, YRES, WINDOW_TITLE, glfwGetPrimaryMonitor(), NULL);
    if (!windowPtr) {
        glfwTerminate();
        cerr << "Error creating GLFW-window!" << endl;
        exit(EXIT_FAILURE);
    }
    glfwMakeContextCurrent(windowPtr);

    // Init GL
    if (gl3wInit()) {
        glfwDestroyWindow(windowPtr);
        glfwTerminate();
        cerr << "Error initializing GL3W!" << endl;
        exit(EXIT_FAILURE);
    }

    // Set vsync on
    glfwSwapInterval(1);

    // Init GL settings
    glViewport(0, 0, XRES, YRES);
    glClearColor(0.f, 0.f, 0.f, 1.f);

    GLenum error = glGetError();
    if(error != GL_NO_ERROR) {
        glfwDestroyWindow(windowPtr);
        glfwTerminate();
        cerr << "Error initializing GL!" << endl;
        exit(EXIT_FAILURE);
    }

#ifdef GUI
    // Setup imgui
    ImGui_ImplGlfwGL3_Init(windowPtr, true);
    ImGuiWindowFlags logWindowFlags= 0;
    logWindowFlags |= ImGuiWindowFlags_NoTitleBar;
    logWindowFlags |= ImGuiWindowFlags_AlwaysAutoResize;
    bool showLog = true;

    Logger logger;
    logger.AddLog("[gl] Context: %s\n     GLSL: %s\n",
                   glGetString(GL_VERSION),
                   glGetString(GL_SHADING_LANGUAGE_VERSION));

    bool showHAX= true;

    // Capture cout for logging
    std::stringstream logCout;
    std::streambuf* oldCout = std::cout.rdbuf(logCout.rdbuf());
#endif // GUI

    // Set glfw-callbacks, these will pass to imgui's callbacks if overridden
    glfwSetWindowSizeCallback(windowPtr, windowSizeCallback);
    glfwSetKeyCallback(windowPtr, keyCallback);
    glfwSetCursorPosCallback(windowPtr, cursorCallback);
    glfwSetMouseButtonCallback(windowPtr, mouseButtonCallback);

    Quad q;

    // Set up audio
    std::string musicPath(RES_DIRECTORY);
    musicPath += "music/gthon18.mp3";
    AudioStream::getInstance().init(musicPath, 175.0, 8);
    int32_t streamHandle = AudioStream::getInstance().getStreamHandle();

    // Set up rocket
    sync_device *rocket = sync_create_device("sync");
    if (!rocket) cout << "[rocket] failed to init" << endl;

    // Init rocket tracks here
    const sync_track* activeScene = sync_get_track(rocket, "activeScene");

    // Set up scenes
    std::string vertPath(RES_DIRECTORY);
    vertPath += "shader/basic_vert.glsl";
    std::vector<std::unique_ptr<Scene>> scenes;
    std::string fragPath(RES_DIRECTORY);
    fragPath = RES_DIRECTORY;
    fragPath += "shader/plasma3d_frag.glsl";
    scenes.emplace_back(std::make_unique<Scene>(std::vector<std::string>({vertPath, fragPath}),
                          std::vector<std::string>({}), rocket));
    // Keksi tähän
    fragPath = RES_DIRECTORY;
    fragPath += "shader/barfft_frag.glsl";
    scenes.emplace_back(std::make_unique<Scene>(std::vector<std::string>({vertPath, fragPath}),
                        std::vector<std::string>({""}), rocket));

    // Set up post processing pass
    TextureParams rgba16fParams = {GL_RGBA16F, GL_RGBA, GL_FLOAT,
                                   GL_LINEAR, GL_LINEAR,
                                   GL_CLAMP_TO_BORDER, GL_CLAMP_TO_BORDER};

    FrameBuffer mainFbo(XRES, YRES, std::vector<TextureParams>({rgba16fParams}));


    std::string postFragPath(RES_DIRECTORY);
    postFragPath += "shader/post_frag.glsl";
    ShaderProgram postShader(vertPath, postFragPath);

#ifdef TCPROCKET
    // Try connecting to rocket-server
    int rocketConnected = sync_tcp_connect(rocket, "localhost", SYNC_DEFAULT_PORT) == 0;
    if (!rocketConnected)
        cout << "[rocket] failed to connect" << endl;
#endif // TCPROCKET

    Timer reloadTime;
    Timer globalTime;
    GpuProfiler sceneProf(5);
    GpuProfiler postProf(5);

    GLfloat haxColor[] = { 0.f, 0.f, 0.f };
    GLfloat haxPos[] = { 0.f, 0.f, 0.f };

    GLfloat fftData[1024];

#ifdef MUSIC_AUTOPLAY
    AudioStream::getInstance().play();
#endif // MUSIC_AUTOPLAY

    // Run the main loop
    while (!glfwWindowShouldClose(windowPtr)) {
        glfwPollEvents();

        // Handle resize
        if (RESIZED) {
            mainFbo.resize(XRES, YRES);
            RESIZED = false;
        }

        // Sync
        double syncRow = AudioStream::getInstance().getRow();

#ifdef TCPROCKET
        // Try re-connecting to rocket-server if update fails
        // Drops all the frames, if trying to connect on windows
        if (sync_update(rocket, (int)floor(syncRow), &audioSync, (void *)&streamHandle))
            sync_tcp_connect(rocket, "localhost", SYNC_DEFAULT_PORT);
#endif // TCPROCKET

#ifdef GUI
        ImGui_ImplGlfwGL3_NewFrame();
#endif // GUI

        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

#ifdef GUI
        // Update imgui
        {
            ImGui::SetNextWindowSize(ImVec2(LOGW, LOGH), ImGuiSetCond_Once);
            ImGui::SetNextWindowPos(ImVec2(LOGM, YRES - LOGH - LOGM), ImGuiSetCond_Always);
            ImGui::Begin("Log", &showLog, logWindowFlags);
            ImGui::Text("Frame: %.1f Scene: %.1f Post: %.1f",
                        1000.f / ImGui::GetIO().Framerate, sceneProf.getAvg(), postProf.getAvg());
            if (logCout.str().length() != 0) {
                logger.AddLog("%s", logCout.str().c_str());
                logCout.str("");
            }
            logger.Draw();
            ImGui::End();

            ImGui::Begin("HAX", &showHAX, 0);
            ImGui::SliderFloat3("color", haxColor, 0.f, 1.f);
            ImGui::SliderFloat3("position", haxPos, -1.f, 1.f);
            ImGui::End();
        }
#endif // GUI

        // Get current scene
        Scene& scene = *scenes[(size_t)(float)sync_get_val(activeScene, syncRow)];

        // Try reloading the shader every 0.5s
        if (reloadTime.getSeconds() > 0.5f) {
            scene.reload();
            postShader.reload();
            reloadTime.reset();
        }

        AudioStream::getInstance().getFFT(fftData);
        std::vector<GLfloat> fftNew(8, 0.f);
        for (int i = 0; i < 8; ++i) {
            for (int j = i * 128; j < (i + 1) * 128; ++j) {
                fftNew[i] += fftData[j];
            }
            fftNew[i] /= 8.f;
        }

        std::vector<GLfloat> delayAvg(8);
        for (int i = 0; i < 8; ++i) {
            delayAvg[i] = 0.8 * fft8Vecs[0][i] + 0.2 * fftNew[i];
        }
        fft8Vecs.erase(fft8Vecs.begin());
        fft8Vecs.push_back(std::move(fftNew));

        sceneProf.startSample();
        scene.bind(syncRow);
        mainFbo.bindWrite();
        glUniform1f(scene.getULoc("uTime"), globalTime.getSeconds());
        GLfloat res[] = {static_cast<GLfloat>(XRES), static_cast<GLfloat>(YRES)};
        glUniform2fv(scene.getULoc("uRes"), 1, res);
        glUniform2fv(scene.getULoc("uMPos"), 1, CURSOR_POS);
        glUniform3fv(scene.getULoc("uColor"), 1, haxColor);
        glUniform3fv(scene.getULoc("uPos"), 1, haxPos);
        glUniform1fv(scene.getULoc("uFFT"), 8, delayAvg.data());
        q.render();
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
        sceneProf.endSample();


        postProf.startSample();
        glViewport(0, 0, XRES, YRES);
        postShader.bind();
        glUniform2fv(postShader.getULoc("uRes"), 1, res);
        glUniform1f(postShader.getULoc("uScene"), (size_t)(float)sync_get_val(activeScene, syncRow));
        mainFbo.bindRead(0, GL_TEXTURE0, postShader.getULoc("uHdrSampler"));
        q.render();
        postProf.endSample();

#ifdef GUI
        ImGui::Render();
#endif // GUI

        glfwSwapBuffers(windowPtr);

#ifdef MUSIC_AUTOPLAY
        if (!AudioStream::getInstance().isPlaying()) glfwSetWindowShouldClose(windowPtr, GLFW_TRUE);
#endif // MUSIC_AUTOPLAY
    }

    // Save rocket tracks
    sync_save_tracks(rocket);

    // Release resources
    sync_destroy_device(rocket);

#ifdef GUI
    std::cout.rdbuf(oldCout);
    ImGui_ImplGlfwGL3_Shutdown();
#endif // GUI

    glfwDestroyWindow(windowPtr);
    glfwTerminate();
    exit(EXIT_SUCCESS);
}
