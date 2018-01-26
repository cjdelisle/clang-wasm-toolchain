#ifndef _WASM32_RESOURCE_H
#define _WASM32_RESOURCE_H
#include <asm-generic/resource.h>
/* defer to versions defined in musl <sys/resource.h> */
#undef RLIM_INFINITY
#undef RLIM_NLIMITS
#endif