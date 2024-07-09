param (
    [string]$VERSION
)

cd $env:HOMEPATH
Write-Host "=====[ Getting Depot Tools ]====="
Invoke-WebRequest -Uri "https://storage.googleapis.com/chrome-infra/depot_tools.zip" -OutFile "depot_tools.zip"
Expand-Archive -Path "depot_tools.zip" -DestinationPath "."

$env:PATH = "$PWD\depot_tools;$env:PATH"
$env:GYP_MSVS_VERSION = "2019"
$env:DEPOT_TOOLS_WIN_TOOLCHAIN = "0"
& gclient

cd depot_tools
& git reset --hard 8d16d4a
cd ..
$env:DEPOT_TOOLS_UPDATE = "0"

New-Item -ItemType Directory -Path "v8"
cd v8

Write-Host "=====[ Fetching V8 ]====="
& fetch v8
cd v8
& git checkout "refs/tags/$VERSION"
& git config --system core.longpaths true
& gclient sync

if ($VERSION -eq "10.6.194") {
    Write-Host "=====[ patch 10.6.194 ]====="
    node "$PSScriptRoot\node-script\do-gitpatch.js" -p "$env:GITHUB_WORKSPACE\patches\win_msvc_v10.6.194.patch"
}

if ($VERSION -eq "9.4.146.24") {
    Write-Host "=====[ patch jinja for python3.10+ ]====="
    cd third_party\jinja2
    node "$PSScriptRoot\node-script\do-gitpatch.js" -p "$env:GITHUB_WORKSPACE\patches\jinja_v9.4.146.24.patch"
    cd ../..
}

node "$PSScriptRoot\node-script\do-gitpatch.js" -p "$env:GITHUB_WORKSPACE\patches\intrin.patch"

Write-Host "=====[ add ArrayBuffer_New_Without_Stl ]====="
node "$PSScriptRoot\node-script\add_arraybuffer_new_without_stl.js" .

node "$PSScriptRoot\node-script\patchs.js" . $VERSION

Write-Host "=====[ Building V8 ]====="
if ($VERSION -eq "10.6.194") {
    & gn gen out.gn\x86.release -args='target_os="win" target_cpu="x86" v8_use_external_startup_data=false v8_enable_i18n_support=false is_debug=false v8_static_library=true is_clang=false strip_debug_info=true symbol_level=0 v8_enable_pointer_compression=false v8_enable_sandbox=false'
} else {
    & gn gen out.gn\x86.release -args='target_os="win" target_cpu="x86" v8_use_external_startup_data=false v8_enable_i18n_support=false is_debug=false v8_static_library=true is_clang=false strip_debug_info=true symbol_level=0 v8_enable_pointer_compression=false'
}

& ninja -C out.gn\x86.release -t clean
& ninja -v -C out.gn\x86.release wee8

New-Item -ItemType Directory -Path "output\v8\Lib\Win32" -Force
Copy-Item -Path "out.gn\x86.release\obj\wee8.lib" -Destination "output\v8\Lib\Win32\" -Force
New-Item -ItemType Directory -Path "output\v8\Inc\Blob\Win32" -Force