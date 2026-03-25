module singuhunt::sig_verify {
    use sui::bcs;
    use sui::ed25519;
    use sui::hash;

    const E_INVALID_PUBLIC_KEY_LEN: u64 = 0;
    const E_UNSUPPORTED_SCHEME: u64 = 1;
    const E_INVALID_SIGNATURE_LEN: u64 = 2;

    const ED25519_FLAG: u8 = 0x00;
    const ED25519_SIG_LEN: u64 = 64;
    const ED25519_PK_LEN: u64 = 32;

    public fun derive_address_from_public_key(public_key: vector<u8>): address {
        assert!(public_key.length() == ED25519_PK_LEN, E_INVALID_PUBLIC_KEY_LEN);

        let mut concatenated = vector[ED25519_FLAG];
        vector::append(&mut concatenated, public_key);
        sui::address::from_bytes(hash::blake2b256(&concatenated))
    }

    public fun verify_personal_message_signature(
        message: vector<u8>,
        signature: vector<u8>,
        expected_address: address,
    ): bool {
        let len = signature.length();
        assert!(len >= 1, E_INVALID_SIGNATURE_LEN);

        let flag = signature[0];
        let (sig_len, pk_len) = match (flag) {
            ED25519_FLAG => (ED25519_SIG_LEN, ED25519_PK_LEN),
            _ => abort E_UNSUPPORTED_SCHEME,
        };

        let expected_len = 1 + sig_len + pk_len;
        assert!(len == expected_len, E_INVALID_SIGNATURE_LEN);

        let raw_sig = extract_bytes(&signature, 1, 1 + sig_len);
        let raw_public_key = extract_bytes(&signature, 1 + sig_len, expected_len);
        let signer_address = derive_address_from_public_key(raw_public_key);
        if (signer_address != expected_address) {
            return false
        };

        // The TypeScript SDK signs `PersonalMessage` as:
        // blake2b( intent || bcs::to_bytes(message) )
        let mut intent_message = x"030000";
        vector::append(&mut intent_message, bcs::to_bytes(&message));
        let digest = hash::blake2b256(&intent_message);

        match (flag) {
            ED25519_FLAG => ed25519::ed25519_verify(&raw_sig, &raw_public_key, &digest),
            _ => abort E_UNSUPPORTED_SCHEME,
        }
    }

    fun extract_bytes(source: &vector<u8>, start: u64, end: u64): vector<u8> {
        vector::tabulate!(end - start, |i| source[start + i])
    }
}
