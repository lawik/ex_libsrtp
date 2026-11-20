/*
 * Makes the vendored libsrtp's public header available under the
 * <srtp2/srtp.h> name an installed libsrtp2 uses, so the NIF sources include
 * it the same way they would include a system libsrtp.
 */
#include "../../libsrtp/include/srtp.h"
