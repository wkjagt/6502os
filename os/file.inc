.global print_file_name
.global clear_dir
.global clear_fat
.global load_dir
.global load_fat
.global show_dir
.global format_drive
.global save_dir
.global find_empty_page
.global format_drive
.global save_file
.global load_file
.global add_to_dir
.global find_empty_dir
.global delete_dir
.global delete_file
.global save_fat
.global find_file

.globalzp error_code
.globalzp dir_page

;todo: use segments for buffers
LAST_PAGE               = $FF           ; the marker used in the FAT to mark the last page of a file
FAT_BUFFER              = $0400         ; where the FAT lives in RAM. todo: use segment
DIR_BUFFER              = $0500         ; where the directory lives in RAM. todo: use segment
MAX_FILE_NAME_LEN       = 8             ; the maximum length of a file name
DIR_ENTRY_SIZE          = 16            ; the number of bytes taken up by one entry in the directory
DIR_PAGE_COUNT          = 4             ; the number of pages on a drive reserved for the directory
DIR_START_PAGE_OFFSET   = 8             ; the offset in an entry where the first page of the data is stored
DIR_FILE_SIZE_OFFSET    = 9             ; the offset in an entry where the file size is stored

; todo, use: https://www.cc65.org/doc/ca65-11.html#ss11.33
ERR_DIR_FULL            = 1             ; no more space available for new directory entries
ERR_DRIVE_FULL          = 2             ; no more space available in the FAT
ERR_FILE_NOT_FOUND      = 3             ; no file matching a name was found in the directory
ERR_FILE_EXISTS         = 4             ; a file with the specified name when saving already exists
ERR_NO_DATA             = 5             ; No data to save because load_size (in zero page) is 0