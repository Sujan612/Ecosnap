# 🌱 Ecosnap

**Ecosnap** is an AI-powered mobile application that identifies environmental species using image recognition and provides detailed ecological insights in real time.

---

## 🚀 Features

* 📸 **Image Recognition**
  Capture or upload images to identify species using a TensorFlow Lite model.

* 🧠 **AI-Powered Classification**
  Uses trained `.tflite` models to classify environmental objects/species with high accuracy.

* 📚 **Detailed Species Information**
  Get in-depth information about identified species including characteristics and relevance.

* 🌐 **Dynamic Image Integration**
  Fetches high-quality images using the Unsplash API.

* 📱 **Smooth Mobile UI**
  Built with Flutter for a responsive and cross-platform experience.

---

## 🛠️ Tech Stack

* **Frontend:** Flutter (Dart)
* **Machine Learning:** TensorFlow Lite
* **Backend Services:** Firebase
* **API Integration:** Unsplash API

---

## 📂 Project Structure

```
lib/
 ├── main.dart
 ├── screens/
 │    ├── home.dart
 │    ├── recognition.dart
 │    ├── species_info.dart
 │    └── species_info_details.dart
 ├── widgets/
 ├── services/
 │    └── unsplash_service.dart
 └── navigation/
      └── bottomnavbar.dart
```

---

## ⚙️ Installation

1. Clone the repository:

```bash
git clone https://github.com/your-username/ecosnap.git
```

2. Navigate to the project:

```bash
cd ecosnap
```

3. Install dependencies:

```bash
flutter pub get
```

4. Run the app:

```bash
flutter run
```

---

## 📸 How It Works

1. User captures or uploads an image
2. The app processes the image using a TensorFlow Lite model
3. The model predicts the species
4. The app displays relevant information and images

---

## 🔮 Future Improvements

* 🌍 Location-based species detection
* 📊 Scan history and favorites
* 🧠 Improved AI model accuracy
* 🌐 Web version of the application
* 👤 User authentication and personalization

---

## 🤝 Contributing

Contributions are welcome! Feel free to fork the repo and submit a pull request.

---

## 📄 License

This project is for educational purposes. You can modify and use it with proper credit.

---

## 👨‍💻 Author

**Sujan Khatri**
Computer Engineer | Flutter Developer | AI Enthusiast

---

## ⭐ Show Your Support

If you like this project, consider giving it a ⭐ on GitHub!
