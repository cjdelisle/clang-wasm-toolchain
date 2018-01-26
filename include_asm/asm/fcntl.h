#ifndef _WASM32_FCNTL_H
#define _WASM32_FCNTL_H

/* defer to types defined by musl in <fcntl.h> */

#define HAVE_ARCH_STRUCT_FLOCK
#define HAVE_ARCH_STRUCT_FLOCK64
#define f_owner_ex _asm_f_owner_ex
#include <asm-generic/fcntl.h>
#undef HAVE_ARCH_STRUCT_FLOCK
#undef HAVE_ARCH_STRUCT_FLOCK64
#undef f_owner_ex

#undef O_ACCMODE
#undef O_RDONLY
#undef O_WRONLY
#undef O_RDWR
#undef FASYNC
#undef F_GETLK64
#undef F_SETLK64
#undef F_SETLKW64

#include <fcntl.h>

#endif