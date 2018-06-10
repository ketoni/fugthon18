cmake_minimum_required(VERSION 3.4)

project(veipoer)

# Platform specific settings
if (MSVC)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /Wall")
else()
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14 -Wall -Wextra -pedantic")
    if (APPLE)
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -framework Cocoa -framework IOKit -framework CoreVideo")
    endif()
endif()

find_package(OpenGL REQUIRED)

add_subdirectory(ext)

include_directories(include ext/rocket/lib ext/bass)

# Add full path to res directory
add_definitions(-DRES_DIRECTORY="${CMAKE_CURRENT_SOURCE_DIR}/res/")

# WIN32 tells to not build a cmd-app on windows, includes populate vs-project
add_executable(veipoer WIN32
    "src/audioStream.cpp"
    "src/frameBuffer.cpp"
    "src/gpuProfiler.cpp"
    "src/main.cpp"
    "src/quad.cpp"
    "src/scene.cpp"
    "src/shaderProgram.cpp"
    "src/texture.cpp"
    "src/timer.cpp"
    "include/audioStream.hpp"
    "include/frameBuffer.hpp"
    "include/gpuProfiler.hpp"
    "include/quad.hpp"
    "include/scene.hpp"
    "include/shaderProgram.hpp"
    "include/texture.hpp"
    "include/timer.hpp"
)

target_link_libraries(veipoer
    PRIVATE
    ${OPENGL_LIBRARIES}
    glfw
    libgl3w
    librocket
    imgui
)
if (MSVC)
    target_link_libraries(veipoer
        PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/ext/bass/lib/bass.lib
    )
elseif (APPLE)
    target_link_libraries(veipoer
        PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/ext/bass/lib/libbass.dylib
    )
else()
    target_link_libraries(veipoer
        PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/ext/bass/lib/libbass.so
    )
endif()

# Copy dynamic libraries to build folder after build
# A cleaner way of doing this even with msvc's build structure?
add_custom_command(TARGET veipoer POST_BUILD
                   COMMAND ${CMAKE_COMMAND} -E copy_directory
                           ${CMAKE_SOURCE_DIR}/ext/bass/lib
                           $<TARGET_FILE_DIR:veipoer>)
