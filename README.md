# Hyprland on an Atomic Distro

## Disclaimer

Firstly, this guide is meant to help those who are either less tech-savy or just unfamiliar with linux in general. If you are already familiar with linux and containers, feel free to just skin the changes made in `Containerfile` and `build_files/build.sh`. That will be all you really need.

In addition, this guide applies to Universal Blue based images. In particular, I will be using Bazzite on a non-Nvidia GPU. I plan to experiment with an Nvidia GPU later.

Further, this guide is not meant to espouse "best practices". It is only meant to offer an simple approach to getting Hyprland installed onto an atomic distro. For more information on making a custom image, refer to the [Blue Build documentation](https://blue-build.org/learn/mindset).

Lastly, some of this information will be redundant as it is also in the README.md of the [template repository](https://github.com/ublue-os/image-template). I will be repeating it here for completeness' sake.

## Forking the Template Repository

Firstly, you will want to navigate to the [Universal Blue Template Repository](https://github.com/ublue-os/image-template) and add the template to your own github account by clicking the green "Use this template" button. Now we can start customizing the image by editing two main files:

1. Containerfile
2. build_files/build.sh

### Containerfile

In the Containerfile, we will make only one customization: choosing a base image. A list of images can be found [here](https://github.com/orgs/ublue-os/packages). For this tutorial, I'll be opting to use Bazzite with the Gnome DE with a non-Nvidia card. As such, our base image needs to point to `ghcr.io/ublue-os/bazzite-gnome:stable`.

### build.sh

For the more granular customization, we switch focus to the `build_files/build.sh` file. Here, we can do things like create directories, enable COPR repositories and install packages that will be included in the final image. As such, we will leverage this functionality to install Hyprland and other packages that make our Hyprland setup more feature-rich such as Hyprlock and Hypridle.

Some of the packages we will need are not available using DNF alone, so we will first need to leverage COPR to make these packages available. For Hyprland, we just need `solopasha/hyprland`. I'll also add `erikreider/SwayNotificationCenter` for notifications and `pgdev/ghostty`, a terminal I'm trying out since my preferred terminal, Wezterm, is buggy in Hyprland. Now, to enable these copr repositories, normally we would run `dnf5 -y copr enable <repo/package>` like `dnf5 -y copr enable solopash/hyprland`. However, this has failed for me during the install phase stating that the package isn't available. I'm not sure the cause of this since it works for some packages and fails for others. However, I do have a solution, so we will use it.

In the `build.sh` file we will create a custom function that will fetch the copr repository and make the packages available to install.

```bash
RELEASE="$(rpm -E %fedora)"
set -ouex pipefail

enable_copr() {
    repo="$1"
    repo_with_dash="${repo/\//-}"
    wget "https://copr.fedorainfracloud.org/coprs/${repo}/repo/fedora-${RELEASE}/${repo_with_dash}-fedora-${RELEASE}.repo" \
        -O "/etc/yum.repos.d/_copr_${repo_with_dash}.repo"
}
```

This function take a repository found in COPR and fetches it according to the current release of Fedora, and adds it to your list of repositories so its packages may be installed.

Now, we can call it as so:

```bash
enable_copr solopasha/hyprland
enable_copr erikreider/SwayNotificationCenter
enable_copr pgdev/ghostty
```

Next, we actually install the packages:

```bash
dnf5 install -y --setopt=install_weak_deps=False \
    xdg-desktop-portal-hyprland \
    hyprland \
    hyprlock \
    hypridle \
    hyprland-qtutils \
    pyprland \
    waybar \
    wofi \
    rofi \
    swaync \
    wl-clipboard \
    grim \
    brightnessctl \
    pavucontrol \
    network-manager-applet \
    clipman \
    nwg-drawer \
    wdisplays \
    pavucontrol \
    SwayNotificationCenter \
    NetworkManager-tui \
    tmux \
    ghostty \
    blueman
```

That's it. By installing the packages here, they will be available in our final image.

## Building the Image

Now that our template is customized to our liking, we need to actually build the image. The steps for doing so are included in the `README.md`, but I will go over them here.

1. Create Keys for Container Signing
2. Upload _PRIVATE_ key to Github as a Secret
3. Commit _PUBLIC_ key alongside other repository files
4. Push commit to Github which kicks off build process

### Container Signing

To use Universal Blue images, you must implement container signing. This is a security measure that verifies the image has not been tampered with and is exactly as the end-user of the image expects. If we were to forego this step, the image will fail to build.

As such, we need to first install the [cosign CLI tool](https://edu.chainguard.dev/open-source/sigstore/cosign/how-to-install-cosign/#installing-cosign-with-the-cosign-binary).

Before generating the keys, be sure to not input a password. When prompted, just press `enter`.
Next, we run the following command from the root of our repo:

```bash
cosign generate-key-pair
```

Now we have two keys:

1. A private key called `cosign.key`
1. A public key called `cosign.pub`

> [!WARNING]
> Be careful to _never_ commit `cosign.key` into your git repo.
> In order to prevent accidentally committing the private key, the `.gitignore` file should already contain `cosign.key`. However, it's best to double check.

### Upload Private Key

This can also be done manually. Go to your repository settings, under `Secrets and Variables` -> `Actions`
![image](https://user-images.githubusercontent.com/1264109/216735595-0ecf1b66-b9ee-439e-87d7-c8cc43c2110a.png)
Add a new secret and name it `SIGNING_SECRET`, then paste the contents of `cosign.key` into the secret and save it. Make sure it's the .key file and not the .pub file. Once done, it should look like this:
![image](https://user-images.githubusercontent.com/1264109/216735690-2d19271f-cee2-45ac-a039-23e6a4c16b34.png)

(CLI instructions) If you have the `github-cli` installed, run:

```bash
gh secret set SIGNING_SECRET < cosign.key
```

### Commit Public Key

As for the public key, we will now add it and commit it alongside all of our changes to `Containerfile` and `build.sh`.

To do so, you can `cd` into the root of your repository and type `git add cosign.pub build.sh`.

### Push commit and Wait for Build

To push this to your remote repo, first commit the staged files using `git commit -m 'added publish cosign key and custom build.sh'` and then push using `git push`.

### Notes

Note: the template provides a comment in `build_files/build.sh` saying you can disable the copr repos you've installed so they don't make it into the final image. However, whenever I have tried this myself, the image fails to build. As such, We'll forego this step and live with it until a solution is found.

Note: For those uninitiated with container images, the `:stable` is a tag helping to specify which version of this image to use. We could also opt for the `:latest` tag.

Note, on forking vs using a template. Using as a template makes the repository detached from the original repo and doesn't preserve the git history. In this way, you can do as you will with it. If you wanted to preserve the commit history and potentially create a PR for the original repo, then you may fork you can also fork the repository, but you likely won't need to.

### Todo

[ ] Explain what kind of packages to install here using build.sh and what should be installed in user land (aka using nix for example).
