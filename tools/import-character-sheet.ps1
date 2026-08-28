[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Source,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9_-]+$')]
    [string]$Id,

    [Parameter(Mandatory = $true)]
    [string]$DisplayName,

    [Parameter(Mandatory = $true)]
    [ValidateRange(0, 9999)]
    [int]$Order,

    [bool]$UnlockedByDefault = $true,

    [string]$OutputRoot = (Join-Path (Split-Path -Parent $PSScriptRoot) 'assets\characters'),

    [switch]$Force,
    [switch]$Validate
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$drawingAssemblies = [AppDomain]::CurrentDomain.GetAssemblies() |
    Where-Object { $_.FullName -match 'System.Drawing|System.Private.Windows' } |
    Select-Object -ExpandProperty Location

if (-not ('RopeKingCharacterSheet' -as [type])) {
    Add-Type -ReferencedAssemblies $drawingAssemblies -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;

public static class RopeKingCharacterSheet
{
    private static bool IsConnectedBackground(byte[] pixels, int offset)
    {
        int b = pixels[offset];
        int g = pixels[offset + 1];
        int r = pixels[offset + 2];
        int a = pixels[offset + 3];
        if (a == 0) return true;
        int min = Math.Min(r, Math.Min(g, b));
        int max = Math.Max(r, Math.Max(g, b));
        return min > 218 && max - min < 24;
    }

    public static Bitmap RemoveConnectedBackground(string path)
    {
        using (var source = new Bitmap(path))
        {
            var bitmap = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb);
            using (var graphics = Graphics.FromImage(bitmap))
            {
                graphics.CompositingMode = System.Drawing.Drawing2D.CompositingMode.SourceCopy;
                graphics.DrawImageUnscaled(source, 0, 0);
            }

            var rect = new Rectangle(0, 0, bitmap.Width, bitmap.Height);
            var data = bitmap.LockBits(rect, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
            int stride = data.Stride;
            byte[] pixels = new byte[stride * bitmap.Height];
            Marshal.Copy(data.Scan0, pixels, 0, pixels.Length);
            int count = bitmap.Width * bitmap.Height;
            bool[] visited = new bool[count];
            int[] queue = new int[count];
            int head = 0;
            int tail = 0;

            Action<int, int> enqueue = (x, y) => {
                if (x < 0 || y < 0 || x >= bitmap.Width || y >= bitmap.Height) return;
                int index = y * bitmap.Width + x;
                if (visited[index]) return;
                int offset = y * stride + x * 4;
                if (!IsConnectedBackground(pixels, offset)) return;
                visited[index] = true;
                queue[tail++] = index;
            };

            for (int x = 0; x < bitmap.Width; x++) {
                enqueue(x, 0);
                enqueue(x, bitmap.Height - 1);
            }
            for (int y = 0; y < bitmap.Height; y++) {
                enqueue(0, y);
                enqueue(bitmap.Width - 1, y);
            }

            while (head < tail)
            {
                int index = queue[head++];
                int x = index % bitmap.Width;
                int y = index / bitmap.Width;
                pixels[y * stride + x * 4 + 3] = 0;
                enqueue(x - 1, y);
                enqueue(x + 1, y);
                enqueue(x, y - 1);
                enqueue(x, y + 1);
            }

            Marshal.Copy(pixels, 0, data.Scan0, pixels.Length);
            bitmap.UnlockBits(data);
            return bitmap;
        }
    }

    public static void Split(string sourcePath, string idlePath, string jumpPath)
    {
        using (var sheet = RemoveConnectedBackground(sourcePath))
        {
            if (sheet.Width < 5 || sheet.Height < 1)
                throw new InvalidDataException("The source sheet is too small.");
            int cellWidth = sheet.Width / 5;

            using (var idle = new Bitmap(cellWidth, sheet.Height, PixelFormat.Format32bppArgb))
            using (var graphics = Graphics.FromImage(idle))
            {
                graphics.CompositingMode = System.Drawing.Drawing2D.CompositingMode.SourceCopy;
                graphics.DrawImage(sheet, new Rectangle(0, 0, cellWidth, sheet.Height), new Rectangle(0, 0, cellWidth, sheet.Height), GraphicsUnit.Pixel);
                idle.Save(idlePath, ImageFormat.Png);
            }

            using (var jump = new Bitmap(cellWidth * 4, sheet.Height, PixelFormat.Format32bppArgb))
            using (var graphics = Graphics.FromImage(jump))
            {
                graphics.CompositingMode = System.Drawing.Drawing2D.CompositingMode.SourceCopy;
                graphics.DrawImage(sheet, new Rectangle(0, 0, cellWidth * 4, sheet.Height), new Rectangle(cellWidth, 0, cellWidth * 4, sheet.Height), GraphicsUnit.Pixel);
                jump.Save(jumpPath, ImageFormat.Png);
            }
        }
    }
}
'@
}

$sourcePath = (Resolve-Path -LiteralPath $Source).Path
$outputRootPath = [System.IO.Path]::GetFullPath($OutputRoot)
$destination = Join-Path $outputRootPath $Id

if (Test-Path -LiteralPath $destination) {
    if (-not $Force) {
        throw "캐릭터 '$Id' 폴더가 이미 있습니다. 교체하려면 -Force를 사용하세요: $destination"
    }
} else {
    [System.IO.Directory]::CreateDirectory($destination) | Out-Null
}

$idlePath = Join-Path $destination 'idle.png'
$jumpPath = Join-Path $destination 'jump_sheet.png'
[RopeKingCharacterSheet]::Split($sourcePath, $idlePath, $jumpPath)

$metadata = [ordered]@{
    display_name = $DisplayName
    order = $Order
    unlocked_by_default = $UnlockedByDefault
}
$metadataJson = $metadata | ConvertTo-Json
[System.IO.File]::WriteAllText((Join-Path $destination 'character.json'), $metadataJson + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))

Write-Host "캐릭터 생성 완료: $destination"
Write-Host "  idle: $idlePath"
Write-Host "  jump: $jumpPath"

if ($Validate) {
    $projectRoot = Split-Path -Parent $PSScriptRoot
    $defaultCharacterRoot = Join-Path $projectRoot 'assets\characters'
    if ([System.IO.Path]::GetFullPath($outputRootPath) -ne [System.IO.Path]::GetFullPath($defaultCharacterRoot)) {
        Write-Warning '-Validate는 기본 assets/characters 출력일 때만 실행됩니다.'
    } else {
        Push-Location $projectRoot
        try {
            & godot_console.exe --headless --path . --editor --quit
            if ($LASTEXITCODE -ne 0) { throw 'Godot 에셋 가져오기 실패' }
            & godot_console.exe --headless --path . --script res://tests/rope_logic_test.gd
            if ($LASTEXITCODE -ne 0) { throw '캐릭터 로직 테스트 실패' }
            & git diff --check
            if ($LASTEXITCODE -ne 0) { throw 'git diff --check 실패' }
        } finally {
            Pop-Location
        }
    }
}
