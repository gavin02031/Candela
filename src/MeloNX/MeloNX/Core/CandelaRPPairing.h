/* SPDX-License-Identifier: GPL-2.0-or-later */
/* Adapted from Leviidev/Husk (GPL-2.0-or-later). Keep in step with src/candela-rppairing/src/lib.rs. */
#ifndef CANDELA_RPPAIRING_H
#define CANDELA_RPPAIRING_H

#include <stddef.h>
#include <stdint.h>

typedef struct CandelaRPPairing CandelaRPPairing;
typedef void (*CandelaRPPairingPinCallback)(const char *pin, void *context);

/* New host identity and a listener on all IPv4 interfaces. NULL on failure,
   with *error set (free with candela_rppairing_string_free). */
CandelaRPPairing *candela_rppairing_new(const char *name, char **error);
uint16_t candela_rppairing_port(const CandelaRPPairing *session);
/* The Bonjour instance name to publish; owned by the session. */
const char *candela_rppairing_service_name(const CandelaRPPairing *session);
size_t candela_rppairing_txt_count(const CandelaRPPairing *session);
const char *candela_rppairing_txt_key(const CandelaRPPairing *session, size_t index);
const char *candela_rppairing_txt_value(const CandelaRPPairing *session, size_t index);
/* Blocks until paired (0), failed (1, *error set) or cancelled (2). On success
   *out_plist and *out_len hold the RPPairing plist (candela_rppairing_bytes_free)
   and *out_device_name the device's name (candela_rppairing_string_free). */
int32_t candela_rppairing_accept(const CandelaRPPairing *session,
                              CandelaRPPairingPinCallback pin_callback, void *pin_context,
                              uint8_t **out_plist, size_t *out_len,
                              char **out_device_name, char **error);
/* Ends a running or future accept with 2. Any thread. */
void candela_rppairing_cancel(const CandelaRPPairing *session);
/* Only after accept has returned (or was never called). */
void candela_rppairing_free(CandelaRPPairing *session);
void candela_rppairing_bytes_free(uint8_t *bytes, size_t len);
void candela_rppairing_string_free(char *string);

#endif /* CANDELA_RPPAIRING_H */

