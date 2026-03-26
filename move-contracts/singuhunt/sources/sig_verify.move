module singuhunt::sig_verify {
    use sui::ed25519;
    use sui::hash;

    const E_INVALID_PUBLIC_KEY_LEN: u64 = 0;
    const E_INVALID_SIGNATURE_LEN: u64 = 1;

    const ED25519_FLAG: u8 = 0x00;
    const ED25519_SIG_LEN: u64 = 64;
    const ED25519_PK_LEN: u64 = 32;

    public fun derive_address_from_public_key(public_key: vector<u8>): address {
        assert!(public_key.length() == ED25519_PK_LEN, E_INVALID_PUBLIC_KEY_LEN);

        let mut concatenated = vector[ED25519_FLAG];
        vector::append(&mut concatenated, public_key);
        sui::address::from_bytes(hash::blake2b256(&concatenated))
    }

    public fun verify_hashed_message_signature(
        signature: vector<u8>,
        public_key: vector<u8>,
        hashed_message: vector<u8>,
    ): bool {
        assert!(public_key.length() == ED25519_PK_LEN, E_INVALID_PUBLIC_KEY_LEN);
        assert!(signature.length() == ED25519_SIG_LEN, E_INVALID_SIGNATURE_LEN);
        ed25519::ed25519_verify(&signature, &public_key, &hashed_message)
    }
}
