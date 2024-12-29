cmake_minimum_required(VERSION 3.18)

set(CMAKE_DISABLE_SOURCE_CHANGES ON)
set(CMAKE_DISABLE_IN_SOURCE_BUILD ON)

project(tfs)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

include(cotire)

add_compile_options(-Wall -pipe -fvisibility=hidden)

set(CMAKE_CXX_STANDARD 20) # Set standard to C++20
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_CXX_FLAGS_PERFORMANCE "${CMAKE_CXX_FLAGS_RELEASE} -march=native")

if (CMAKE_COMPILER_IS_GNUCXX)
    add_compile_options(-fno-strict-aliasing)
endif()

include(FindCXX11)
include(FindLTO)

# Find packages.
find_package(Crypto++ REQUIRED)
find_package(PugiXML REQUIRED)
find_package(MySQL)
find_package(Threads)
find_package(OpenMP REQUIRED)  # Dodane OpenMP
find_package(ZLIB REQUIRED)  # Dodajemy wykrywanie ZLIB

# Obsługa LuaJIT, jeżeli włączona
if(DEFINED USE_LUAJIT AND NOT USE_LUAJIT)
    set(FORCE_LUAJIT ${USE_LUAJIT})
else()
    find_package(LuaJIT)
    set(FORCE_LUAJIT ${LuaJIT_FOUND})
endif()
option(USE_LUAJIT "Use LuaJIT" ${FORCE_LUAJIT})

if(FORCE_LUAJIT)
    if(APPLE)
      set(CMAKE_EXE_LINKER_FLAGS "-pagezero_size 10000 -image_base 100000000")
    endif()
else()
    find_package(Lua REQUIRED)
endif()

# Update Boost to a more flexible version detection
find_package(Boost REQUIRED COMPONENTS system filesystem iostreams)

# Find fmt library
find_package(fmt REQUIRED)

# Tworzenie docelowego pliku wykonawczego
add_subdirectory(src)
add_executable(tfs ${tfs_SRC})

# Dodajemy flagi kompilatora dla OpenMP
if(OpenMP_CXX_FOUND)
    add_compile_options(-fopenmp)  # Dodaj flagę kompilatora OpenMP
    target_link_libraries(tfs PUBLIC OpenMP::OpenMP_CXX)  # Linkujemy z OpenMP
endif()

# Ensure the correct libraries and include paths are added
include_directories(${MYSQL_INCLUDE_DIR} ${LUA_INCLUDE_DIR} ${Boost_INCLUDE_DIRS} ${PUGIXML_INCLUDE_DIR} ${Crypto++_INCLUDE_DIR})

# Dodajemy wymagane biblioteki do linkowania, w tym 'zlib' (lub 'z', jeśli konieczne)
# Link libraries
target_link_libraries(tfs 
    PUBLIC ${ZLIB_LIBRARIES} 
    PUBLIC ${MYSQL_CLIENT_LIBS} 
    PUBLIC ${LUA_LIBRARIES} 
    PUBLIC ${Boost_LIBRARIES} 
    PUBLIC ${PUGIXML_LIBRARIES} 
    PUBLIC ${Crypto++_LIBRARIES} 
    PUBLIC ${CMAKE_THREAD_LIBS_INIT}
    PUBLIC fmt
)

set_target_properties(tfs PROPERTIES COTIRE_CXX_PREFIX_HEADER_INIT "src/otpch.h")
set_target_properties(tfs PROPERTIES COTIRE_ADD_UNITY_BUILD FALSE)

cotire(tfs)
