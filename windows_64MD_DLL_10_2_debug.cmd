set VERSION=%1

cd %HOMEPATH%
echo =====[ Getting Depot Tools ]=====
powershell -command "Invoke-WebRequest https://storage.googleapis.com/chrome-infra/depot_tools.zip -O depot_tools.zip"
7z x depot_tools.zip -o*
set PATH=%CD%\depot_tools;%PATH%
set GYP_MSVS_VERSION=2019
set DEPOT_TOOLS_WIN_TOOLCHAIN=0
call gclient

cd depot_tools
call git reset --hard 8d16d4a
cd ..
set DEPOT_TOOLS_UPDATE=0


mkdir v8
cd v8

echo =====[ Fetching V8 ]=====
call fetch v8
cd v8
call git checkout refs/tags/%VERSION%
cd test\test262\data
call git config --system core.longpaths true
call git restore *
cd ..\..\..\
call gclient sync

@REM echo =====[ Patching V8 ]=====
@REM node %GITHUB_WORKSPACE%\CRLF2LF.js %GITHUB_WORKSPACE%\patches\builtins-puerts.patches
@REM call git apply --cached --reject %GITHUB_WORKSPACE%\patches\builtins-puerts.patches
@REM call git checkout -- .

@REM echo =====[ Patching V8 2]=====
@REM see: https://github.com/nodejs/node/commit/5820d145ad9366677b6bb111727c543811c53c8f
node %~dp0\node-script\patch_cpp_gc.js ./include/v8-cppgc.h


echo =====[ Make dynamic_crt ]=====
node %~dp0\node-script\rep.js  build\config\win\BUILD.gn

echo =====[ commenting out Zc_inline  ]=====
node -e "const fs = require('fs'); fs.writeFileSync('./build/config/compiler/BUILD.gn', fs.readFileSync('./build/config/compiler/BUILD.gn', 'utf-8').replace('\"/Zc:inline\"', '#\"/Zc:inline\"'));

echo =====[ add ArrayBuffer_New_Without_Stl ]=====
node %~dp0\node-script\add_arraybuffer_new_without_stl.js .

echo =====[ Building V8 ]=====
call gn gen out.gn\x64.debug -args="target_os=""win"" target_cpu=""x64"" v8_use_external_startup_data=false v8_enable_i18n_support=false is_debug=true is_clang=false symbol_level=2 v8_enable_pointer_compression=false is_component_build=true treat_warnings_as_errors=false"

call ninja -C out.gn\x64.debug -t clean
call ninja -C out.gn\x64.debug v8

if %ERRORLEVEL% NEQ 0 EXIT /B %ERRORLEVEL%

md output\v8\Lib\Win64DLL
copy /Y out.gn\x64.debug\v8.dll.lib output\v8\Lib\Win64DLL\
copy /Y out.gn\x64.debug\v8_libplatform.dll.lib output\v8\Lib\Win64DLL\
copy /Y out.gn\x64.debug\v8.dll output\v8\Lib\Win64DLL\
copy /Y out.gn\x64.debug\v8_libbase.dll output\v8\Lib\Win64DLL\
copy /Y out.gn\x64.debug\v8_libplatform.dll output\v8\Lib\Win64DLL\
copy /Y out.gn\x64.debug\zlib.dll output\v8\Lib\Win64DLL\
copy /Y out.gn\x64.debug\v8.dll.pdb output\v8\Lib\Win64DLL\
copy /Y out.gn\x64.debug\v8_libbase.dll.pdb output\v8\Lib\Win64DLL\
copy /Y out.gn\x64.debug\v8_libplatform.dll.pdb output\v8\Lib\Win64DLL\
copy /Y out.gn\x64.debug\zlib.dll.pdb output\v8\Lib\Win64DLL\