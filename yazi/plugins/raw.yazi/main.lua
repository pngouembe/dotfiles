-- Preview camera RAW files from the JPEG preview the camera embedded in them,
-- same approach as thumbnailers/raw-thumbnailer: no demosaicing, so it's fast.

local M = {}

-- exiftool extracts the embedded JPEG (JpgFromRaw is full size on most bodies,
-- PreviewImage is the fallback). The JPEG carries no orientation of its own, so
-- the RAW's is applied with magick before downscaling into yazi's cache.
local SCRIPT = [[
raw=$1 cache=$2 w=$3 h=$4 q=$5
tmp=$(mktemp --suffix=.jpg) || exit 1
trap 'rm -f "$tmp"' EXIT
exiftool -b -JpgFromRaw "$raw" >"$tmp" 2>/dev/null
[ -s "$tmp" ] || exiftool -b -PreviewImage "$raw" >"$tmp" 2>/dev/null
[ -s "$tmp" ] || exit 1
case $(exiftool -n -s3 -Orientation "$raw" 2>/dev/null) in
	2) o=TopRight ;; 3) o=BottomRight ;; 4) o=BottomLeft ;; 5) o=LeftTop ;;
	6) o=RightTop ;; 7) o=RightBottom ;; 8) o=LeftBottom ;; *) o=TopLeft ;;
esac
exec magick -define jpeg:size="${w}x${h}" "$tmp" -orient "$o" -auto-orient \
	-resize "${w}x${h}>" -quality "$q" "JPG:$cache"
]]

function M:peek(job)
	local start, cache = os.clock(), ya.file_cache(job)
	if not cache then
		return
	end

	local ok, err = self:preload(job)
	if not ok or err then
		return ya.preview_widget(job, err)
	end

	ya.sleep(math.max(0, rt.preview.image_delay / 1000 + start - os.clock()))

	local _, err = ya.image_show(cache, job.area)
	ya.preview_widget(job, err)
end

function M:seek() end

function M:preload(job)
	local cache = ya.file_cache(job)
	if not cache or fs.cha(cache) then
		return true
	end

	local status, err = Command("sh")
		:arg({
			"-c",
			SCRIPT,
			"sh",
			tostring(job.file.path),
			tostring(cache),
			tostring(rt.preview.max_width),
			tostring(rt.preview.max_height),
			tostring(rt.preview.image_quality),
		})
		:status()

	if not status then
		return true, Err("Failed to start `sh`, error: %s", err)
	elseif not status.success then
		return false, Err("No embedded preview found (exit code %s)", status.code)
	end
	return true
end

function M:spot(job) require("file"):spot(job) end

return M
