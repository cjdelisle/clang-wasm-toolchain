#ifndef _WASM32_SIGCONTEXT_H
#define _WASM32_SIGCONTEXT_H

/*
 * Don't know what we can really relay to the user here since wasm32 is a VM.
 */
struct sigcontext {
	unsigned long trap_no;
	unsigned long error_code;
};

#endif