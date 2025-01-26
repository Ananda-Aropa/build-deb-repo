# **Build DEB Repository**
*Build a DEB repository for the specified packages.*

![GitHub Marketplace](https://img.shields.io/badge/GitHub-Marketplace-blue.svg)  
<!-- [![Test Workflow](https://github.com/DevChall-by-SDCY-and-VXM/build-deb-repo/actions/workflows/test.yml/badge.svg)](https://github.com/DevChall-by-SDCY-and-VXM/build-deb-repo/actions/workflows/test.yml)   -->
[![License](https://img.shields.io/github/license/DevChall-by-SDCY-and-VXM/build-deb-repo.svg)](LICENSE)

## **Overview**  
This GitHub Action creates a DEB repository for specified packages. It supports configuration of repository metadata, architectures, components, and optional GPG signing.

---

## **Features**  
- 📦 **Customizable repository metadata**: Define label, origin, description, architectures, and components.
- 🔐 **Optional GPG signing**: Sign the repository using a GPG key.
- 🚀 **Streamlined workflow**: Easily integrate with your CI/CD pipelines.

---

## **Usage**  

### **Basic Example**  
```yaml
name: Build DEB Repository
on:
  push:
    branches:
      - main
jobs:
  build-repo:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v3

      - name: Build repository
        uses: DevChall-by-SDCY-and-VXM/build-deb-repo@v0.0.8
        with:
          label: "Sample"
          from_metadatas: |
            https://github.com/your/package/releases/latest/download
```

### **Inputs**  
| Name               | Required | Default          | Description                                                                 |
|--------------------|----------|------------------|-----------------------------------------------------------------------------|
| `label`            | ✅       | `null`           | Project name.                                                              |
| `origin`           | ❌       | `null`           | Project origin name or domain name.                                        |
| `desc`             | ✅       | `""`            | Repository description.                                                    |
| `codename`         | ✅       | `unstable`       | Project target distro codename.                                            |
| `architectures`    | ✅       | `source\namd64` | List of architectures of packages.                                         |
| `components`       | ✅       | `main`           | Repository components.                                                     |
| `udeb_components`  | ✅       | `main`           | Repository UDeb components.                                                |
| `gpg_signing_key`  | ❌       | `null`           | The GPG key to use for signing the repository.                             |
| `maintainer`       | ❌       | `null`           | Maintainer of the packages signed with `gpg_signing_key`.                  |
| `from_metadatas`   | ✅       | `null`           | List of package metadata to include in the repository.                     |
| `from_deb_packages`| ✅       | `""`           | List of DEB packages to include in the repository.                         |

### **Outputs**  
| Name           | Description                                           |
|----------------|-------------------------------------------------------|
| `placeholder`  | Placeholder output.                                   |

---

## **Advanced Usage**  
```yaml
name: Advanced DEB Repository Workflow
on:
  pull_request:
    types:
      - opened
      - synchronized
jobs:
  build-repo:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v3

      - name: Build repository with GPG signing
        uses: DevChall-by-SDCY-and-VXM/build-deb-repo@v0.0.8
        with:
          label: "AdvancedSample"
          origin: "example.com"
          desc: "This is an advanced example."
          codename: "stable"
          architectures: |
            source
            amd64
            arm64
          components: "main contrib"
          gpg_signing_key: "<GPG_KEY>"
          maintainer: "Maintainer Name <maintainer@example.com>"
          from_metadatas: |
            https://example.com/releases/latest/
          from_deb_packages: |
            https://example.com/releases/latest/package.deb
```

---

## **Contributing**  
<!-- We welcome contributions! See the [CONTRIBUTING.md](CONTRIBUTING.md) file for details on how to get involved. -->

---

## **License**  
<!-- This repository is licensed under the [MIT License](LICENSE). See the [LICENSE](LICENSE) file for details. -->

---

## **Support**  
If you encounter any issues, please [open an issue](https://github.com/DevChall-by-SDCY-and-VXM/build-deb-repo/issues). For additional support, reach out via [email/contact method].

---

## **Changelog**  
<!-- See the [CHANGELOG.md](CHANGELOG.md) for recent updates and changes. -->

---

## **Marketplace Link**  
[View on GitHub Marketplace](https://github.com/marketplace/actions/build-deb-repo)
