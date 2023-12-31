include (CheckIncludeFileCXX)

if (DirectX_D3D11_4_INCLUDE_FOUND)

    include_directories (BEFORE
        ${DirectX_D3D11_INCLUDE_DIR}
        ${CMAKE_SOURCE_DIR}/thirdparty/directxmath/Inc
    )

    if (MINGW)
        # Several MinGW headers are lacking.  Use our own.
        include_directories (BEFORE
            ${CMAKE_SOURCE_DIR}/thirdparty/mingw/wincodec
        )

        remove_definitions (-D_WIN32_WINNT=0x0602 -DWINVER=0x0602)
        add_definitions (
            #inhibit warnings
            -w

            # Force include this header with tweaks for mingw
            --include ${CMAKE_CURRENT_SOURCE_DIR}/mingw/tweaks.h

            -D_XM_NO_INTRINSICS_
            -D_XM_NO_XMVECTOR_OVERLOADS_
            -DXMINLINE=inline
            -DXM_NO_ALIGNMENT

            -D_WIN32_WINNT=0x0501 -DWINVER=0x0501
        )
        if (CMAKE_SIZEOF_VOID_P EQUAL 8)
            add_definitions (-D_XM_X64_)
        else ()
            add_definitions (-D_XM_X86_)
        endif ()
        set (MINGW_GUID mingw/guid.cpp)
    else ()
        # MSVC uses intrinsics by default, but it seems to expose bugs for some
        # formats.
        add_definitions (-D_XM_NO_INTRINSICS_)
    endif ()

    add_library (directxtex STATIC
        DirectXTex/BC4BC5.cpp
        DirectXTex/BC6HBC7.cpp
        DirectXTex/BC.cpp
        DirectXTex/DirectXTexCompress.cpp
        DirectXTex/DirectXTexConvert.cpp
        #DirectXTex/DirectXTexD3D11.cpp
        #DirectXTex/DirectXTexDDS.cpp
        #DirectXTex/DirectXTexFlipRotate.cpp
        DirectXTex/DirectXTexImage.cpp
        DirectXTex/DirectXTexMipmaps.cpp
        DirectXTex/DirectXTexMisc.cpp
        #DirectXTex/DirectXTexNormalMaps.cpp
        #DirectXTex/DirectXTexResize.cpp
        DirectXTex/DirectXTexTGA.cpp
        DirectXTex/DirectXTexUtil.cpp
        DirectXTex/DirectXTexWIC.cpp
        ${MINGW_GUID}
    )

    set_target_properties (directxtex PROPERTIES C_STANDARD 99 CXX_STANDARD 11)

    install (
        FILES MIT.txt
        DESTINATION ${DOC_INSTALL_DIR}
        RENAME LICENSE-directxtex.txt
    )
endif ()
