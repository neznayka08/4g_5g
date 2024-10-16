cmake_minimum_required(VERSION 3.14)


project(Zero)


set(CMAKE_C_STANDARD 99)


#find_package(PkgConfig REQUIRED)
#pkg_check_modules(PC_ZMQ REQUIRED libzmq)


add_executable(client ./test/client.c)
target_link_libraries(client zmq pcap)
add_executable(server ./test/server.c)
target_link_libraries(server zmq pcap)

# Указываем библиотеку ZeroMQ клиенту и серверу
target_link_libraries(client ${PC_ZMQ_LIBRARIES})
target_link_libraries(server ${PC_ZMQ_LIBRARIES})

# Включаем заголовочные файлы от ZeroMQ
#target_include_directories(client PUBLIC ${PC_ZMQ_INCLUDE_DIRS})
#target_include_directories(server PUBLIC ${PC_ZMQ_INCLUDE_DIRS})

