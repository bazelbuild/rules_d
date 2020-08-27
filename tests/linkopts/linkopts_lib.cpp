#if defined(WIN32)

    #include <windows.h>
    #include <winhttp.h>

    int callLibraryFunction() {
        return 0 == WinHttpCheckPlatform();
    }

#else

    extern "C" {
        char* curl_version(void);
    }

    int callLibraryFunction() {
        return 0 == (unsigned long long)curl_version();
    }

#endif
