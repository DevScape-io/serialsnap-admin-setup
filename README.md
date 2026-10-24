# SerialSnap admin setup

Tools for turning an Apple School Manager or Apple Business API account into a
setup QR code that technicians scan in SerialSnap under
**Add organization › Scan setup QR code**.

| File | What it is | Hosted copy |
|---|---|---|
| [`serialsnap-setup.html`](serialsnap-setup.html) | Browser page. Makes no network requests and saves nothing. | https://serialsnap.devscape.io |
| [`serialsnap-qr.sh`](serialsnap-qr.sh) | Terminal script that draws the same code. Needs `brew install qrencode`. | https://serialsnap.devscape.io/serialsnap-qr.sh |

The QR code can contain your organization's private key. Treat it like the
`.pem` file: show it only to the technician who's scanning, and don't print,
screenshot or share it.

## Check your copy

These fingerprints match the files deployed to serialsnap.devscape.io.

| File | SHA-256 |
|---|---|
| `serialsnap-setup.html` | `e007f5ec784058e9dfd76a796e754af3e8b2a77779f9d7a4e33995a9c9f85f21` |
| `serialsnap-qr.sh` | `4c273a8343d14415c4d06d46954bf8dacb2e64b92b5fe897cbf307fdbc6b75b8` |

Compare a downloaded copy with:

```sh
curl -s https://serialsnap.devscape.io/serialsnap-setup.html | shasum -a 256
curl -s https://serialsnap.devscape.io/serialsnap-qr.sh | shasum -a 256
```

For the most caution, download the file, check its fingerprint, and open it
from disk instead of using the hosted page.

The bundled QR generator is [qrcode-generator](https://github.com/kazuhikoarase/qrcode-generator)
by Kazuhiko Arase, under the MIT License.

SerialSnap admin setup is released under the [MIT License](LICENSE).
