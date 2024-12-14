## Installation
`./install.sh`

## Scripts
- alias.py: quickly generate a "send to" address for email alias services; to be used in-tandem with Espanso
- get-all-virsh-ips: used to get all the IPs of the VMs in a virsh environment
- gh-artifacts: used to download artifacts from a GitHub Actions workflow
- input: used to enable/disable input devices
- install: used to symlink these scripts to /usr/local/bin without the .sh extension
- memdump: used to dump the memory of a process
- s: "secrets"; used to inject secret environment variables into a command
- zed: "EZ sed" - a wrapper around sed that makes it easier to use; taken from [easy-sed](https://github.com/jayalmaraz/easy-sed)

### Rust Scripts
Files in `./rust` are "scripts" that utilize [cargo-script](https://doc.rust-lang.org/nightly/cargo/reference/unstable.html#script). This allows you to bundle an entire Rust program as a single file (including `cargo` dependencies) and run it on systems that have `cargo` installed, in a way that feels similar to how you'd run a Python script.
