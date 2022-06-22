.global get_input
.global clear_input
.globalzp inputbuffer_ptr

.ifndef INPUT_FLAG_CAPS
INPUT_FLAG_CAPS = 1
.endif