cmake_minimum_required(VERSION 3.24)
project(nightcoop_hub LANGUAGES C CXX)

# Link the MSVC runtime statically so the executable can be copied to another PC.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

include(FetchContent)
include(CheckSymbolExists)
find_package(Threads REQUIRED)

# Use the same ENet revision as the Docker build. For offline builds, set
# FETCHCONTENT_SOURCE_DIR_ENET to an existing checkout of this revision.
FetchContent_Declare(enet
    GIT_REPOSITORY https://github.com/lsalzman/enet.git
    GIT_TAG 5a9c537fd464b3c6d3c55e1d3bd47588faf71b42
    SOURCE_SUBDIR cmake-download-only
)
# We define our own static target so upstream options cannot enable shared DLLs.
FetchContent_MakeAvailable(enet)

add_library(enet STATIC
    ${enet_SOURCE_DIR}/callbacks.c
    ${enet_SOURCE_DIR}/compress.c
    ${enet_SOURCE_DIR}/host.c
    ${enet_SOURCE_DIR}/list.c
    ${enet_SOURCE_DIR}/packet.c
    ${enet_SOURCE_DIR}/peer.c
    ${enet_SOURCE_DIR}/protocol.c
)
target_include_directories(enet PUBLIC ${enet_SOURCE_DIR}/include)
if(WIN32)
    target_sources(enet PRIVATE ${enet_SOURCE_DIR}/win32.c)
    target_link_libraries(enet PUBLIC ws2_32 winmm)
else()
    target_sources(enet PRIVATE ${enet_SOURCE_DIR}/unix.c)
    # Detect Unix capabilities instead of assuming Linux headers on every OS.
    foreach(symbol fcntl poll getaddrinfo getnameinfo inet_pton inet_ntop gethostbyname_r gethostbyaddr_r)
        string(TOUPPER ${symbol} upper_symbol)
        check_symbol_exists(${symbol} "sys/types.h;sys/socket.h;netdb.h;arpa/inet.h;fcntl.h;poll.h" HAS_${upper_symbol})
        if(HAS_${upper_symbol})
            target_compile_definitions(enet PRIVATE HAS_${upper_symbol}=1)
        endif()
    endforeach()
    target_compile_definitions(enet PRIVATE HAS_SOCKLEN_T=1 HAS_MSGHDR_FLAGS=1)
endif()

add_library(monocypher STATIC vendor/monocypher/monocypher.c)
add_executable(nightcoop_hub
    tools/hub/main.cpp
    src/HubServer.cpp
    src/NetCrypto.cpp
    src/Log.cpp
)
target_compile_features(nightcoop_hub PRIVATE cxx_std_20)
set_target_properties(nightcoop_hub PROPERTIES CXX_EXTENSIONS OFF)
target_link_libraries(nightcoop_hub PRIVATE enet monocypher Threads::Threads)

if(WIN32)
    # Prevent Windows headers from defining min/max or including legacy Winsock.
    target_compile_definitions(nightcoop_hub PRIVATE NOMINMAX WIN32_LEAN_AND_MEAN)
    target_link_libraries(nightcoop_hub PRIVATE bcrypt)
endif()
if(MSVC)
    target_compile_options(nightcoop_hub PRIVATE /W4 /utf-8 /permissive-)
    target_compile_definitions(nightcoop_hub PRIVATE _CRT_SECURE_NO_WARNINGS)
else()
    target_compile_options(nightcoop_hub PRIVATE -Wall -Wextra -Wno-unused-parameter)
endif()

install(TARGETS nightcoop_hub RUNTIME DESTINATION bin)
