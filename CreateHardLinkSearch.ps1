#create hard links for images matching a tag in a folder called search_results

param(
    [string]$SearchText,
    [string]$Path = ".",
    [string]$FileType = "*.jpeg"
)

if (-not $SearchText) {
    Write-Host "Error: Search text is required." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $Path)) {
    Write-Host "Error: Path '$Path' does not exist." -ForegroundColor Red
    exit 1
}

# Initialize array to store found files
$foundFiles = @()

# Recursively search for files containing search text
$files = Get-ChildItem -Path $Path -Recurse -File -Filter "*.txt"

foreach ($file in $files) {
    $content = Get-Content $file -Raw
    if ($content -like "*$SearchText*") {
        $foundFiles += $file.FullName
        Write-Host "Found '$SearchText' in: $file" -ForegroundColor Green
    }
}

# If no files found, exit gracefully
if ($foundFiles.Count -eq 0) {
    Write-Host "No files found containing the search text." -ForegroundColor Yellow
    exit 0
}

# Create directory for hard links
$destinationDir = Join-Path $Path "search_results" $SearchText
if (-not (Test-Path $destinationDir)) {
    New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
}

# Create text file with found file names
$foundFile = Join-Path $destinationDir "found_files.txt"
$foundFiles | Out-File -FilePath $foundFile -Encoding utf8

Write-Host "Created file: $foundFile" -ForegroundColor Cyan

$jpegFiles = Get-ChildItem -Path $Path -Recurse -Exclude $destinationDir -Filter $FileType

# find jpeg files that include a part of the filename of the found files and create hard links to them in the destination directory
foreach ($file in $foundFiles) {
    $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($file)
    $fileNameWithoutExtension = $fileNameWithoutExtension.Substring(0, $fileNameWithoutExtension.Length - 5) # Remove last 5 characters (e.g., "_data")
    foreach ($jpeg in $jpegFiles) {
        if ($jpeg.Name -like "*$fileNameWithoutExtension*") {
            $destFile = Join-Path $destinationDir $jpeg.Name
            
            # Create hard link
            if (Test-Path $jpeg.FullName) {
                try {
                    New-Item -ItemType HardLink -Path $destFile -Target $jpeg.FullName -Force -ErrorAction Stop
                    Write-Host "Created hard link: $destFile" -ForegroundColor Green
                }
                catch {
                    Write-Host "Failed to create hard link for ${jpeg.FullName}: $_" -ForegroundColor Red
                }
            }
        }
    }
    
}

Write-Host "Search completed. Results saved to $destinationDir." -ForegroundColor Cyan
