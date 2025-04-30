from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives import hmac
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import padding
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes


# The client traffic secret (CLIENT_TRAFFIC_SECRET_0)
client_traffic_secret_0 = bytes.fromhex("4d5af3c81c856c817cedbb57bf9600d6127b8a10f8db83bdd8c4f721acb9f93510cf7bba03e7257b6a83d107628a6f60")

# The encrypted data from the packet
encrypted_data = bytes.fromhex("4420400c08eda8c48095558b56d8e4609284f9da79ae4923f7de77871899c97a47ac2a46f5bbe7a17c778a1c1e506d0db780c95a")

# Derive key using HKDF
hkdf = HKDF(
    algorithm=hashes.SHA256(),
    length=32,  # Key length (256-bit key)
    salt=None,
    info=b"quic encryption",
    backend=default_backend()
)

# Derive the encryption key (first 32 bytes from the secret)
encryption_key = hkdf.derive(client_traffic_secret_0)

# Now you would typically decrypt the data using the derived key
# For this example, let's assume AES-GCM is used for encryption
# You need the nonce/IV and tag from the QUIC packet, so let's simulate it

# Assuming an AES-GCM cipher with an IV (nonce) and a tag, you need to extract them (this is specific to QUIC)
# We'll assume the IV and tag were part of the encrypted data
# In QUIC, the structure of the packet would have these components
iv = b"your_nonce_here"  # replace with actual nonce from QUIC packet
tag = b"your_tag_here"  # replace with actual tag

# Decrypting the data with AES-GCM
cipher = Cipher(algorithms.AES(encryption_key), modes.GCM(iv, tag), backend=default_backend())
decryptor = cipher.decryptor()

# Perform decryption
decrypted_data = decryptor.update(encrypted_data) + decryptor.finalize()

print("Decrypted data:", decrypted_data.decode('utf-8'))