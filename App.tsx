import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  Dimensions,
  StatusBar,
  Alert
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { BlurView } from 'expo-blur';

const { width, height } = Dimensions.get('window');

export default function LoginScreen() {
  const [name, setName] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');

  const handleRegister = () => {
    if (!name || !password || !confirmPassword) {
      Alert.alert('Помилка', 'Будь ласка, заповніть всі поля');
      return;
    }
    
    if (password !== confirmPassword) {
      Alert.alert('Помилка', 'Паролі не співпадають');
      return;
    }
    
    // Тут буде логіка реєстрації
    Alert.alert('Успіх', 'Акаунт створено успішно!');
  };

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="transparent" translucent />
      
      {/* Background Gradient */}
      <LinearGradient
        colors={['#1f1f1f', '#2d2d32', '#232338']}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={styles.background}
      />
      
      {/* Animated Background Elements */}
      <View style={styles.backgroundElements}>
        <View style={styles.floatingElement1} />
        <View style={styles.floatingElement2} />
        <View style={styles.floatingElement3} />
        <View style={styles.geometricShape1} />
        <View style={styles.geometricShape2} />
      </View>
      
      {/* Glass Panel */}
      <BlurView intensity={25} style={styles.glassPanel}>
        <View style={styles.innerPanel}>
          <Text style={styles.title}>Вхід в акаунт</Text>
          
          <View style={styles.formGroup}>
            <Text style={styles.label}>Ім'я користувача</Text>
            <TextInput
              style={styles.input}
              placeholder="Введіть ім'я"
              placeholderTextColor="#999"
              value={name}
              onChangeText={setName}
            />
          </View>
          
          <View style={styles.formGroup}>
            <Text style={styles.label}>Пароль</Text>
            <TextInput
              style={styles.input}
              placeholder="Введіть пароль"
              placeholderTextColor="#999"
              secureTextEntry
              value={password}
              onChangeText={setPassword}
            />
          </View>
          
          <View style={styles.formGroup}>
            <Text style={styles.label}>Пароль повторити</Text>
            <TextInput
              style={styles.input}
              placeholder="Введіть пароль повторити"
              placeholderTextColor="#999"
              secureTextEntry
              value={confirmPassword}
              onChangeText={setConfirmPassword}
            />
          </View>
          
          <TouchableOpacity style={styles.submitBtn} onPress={handleRegister}>
            <Text style={styles.submitBtnText}>Зареєструватися</Text>
          </TouchableOpacity>
          
          <View style={styles.formFooter}>
            <Text style={styles.footerText}>Вже є акаунт? </Text>
            <TouchableOpacity>
              <Text style={styles.footerLink}>Зарегеструватись</Text>
            </TouchableOpacity>
          </View>
        </View>
      </BlurView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  background: {
    position: 'absolute',
    left: 0,
    right: 0,
    top: 0,
    bottom: 0,
  },
  backgroundElements: {
    position: 'absolute',
    width: '100%',
    height: '100%',
  },
  floatingElement1: {
    position: 'absolute',
    width: 120,
    height: 120,
    borderRadius: 60,
    backgroundColor: 'rgba(88, 255, 127, 0.1)',
    top: height * 0.15,
    left: width * 0.8,
    shadowColor: '#58ff7f',
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.3,
    shadowRadius: 20,
    elevation: 5,
  },
  floatingElement2: {
    position: 'absolute',
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: 'rgba(88, 255, 127, 0.08)',
    top: height * 0.7,
    left: width * 0.1,
    shadowColor: '#58ff7f',
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.2,
    shadowRadius: 15,
    elevation: 3,
  },
  floatingElement3: {
    position: 'absolute',
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: 'rgba(88, 255, 127, 0.06)',
    top: height * 0.25,
    left: width * 0.05,
    shadowColor: '#58ff7f',
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.25,
    shadowRadius: 12,
    elevation: 4,
  },
  geometricShape1: {
    position: 'absolute',
    width: 200,
    height: 200,
    backgroundColor: 'rgba(88, 255, 127, 0.03)',
    top: height * 0.05,
    left: width * 0.6,
    transform: [{ rotate: '45deg' }],
    borderRadius: 20,
    shadowColor: '#58ff7f',
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.1,
    shadowRadius: 25,
    elevation: 2,
  },
  geometricShape2: {
    position: 'absolute',
    width: 150,
    height: 150,
    backgroundColor: 'rgba(88, 255, 127, 0.04)',
    top: height * 0.6,
    left: width * 0.7,
    transform: [{ rotate: '30deg' }],
    borderRadius: 75,
    shadowColor: '#58ff7f',
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.15,
    shadowRadius: 18,
    elevation: 3,
  },
  glassPanel: {
    width: Math.min(400, width - 40),
    borderRadius: 20,
    overflow: 'hidden',
    backgroundColor: 'rgba(255, 255, 255, 0.08)',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 8,
    },
    shadowOpacity: 0.3,
    shadowRadius: 32,
    elevation: 16,
  },
  innerPanel: {
    padding: 30,
  },
  title: {
    fontSize: 26,
    fontWeight: '600',
    color: '#58ff7f',
    textAlign: 'center',
    marginBottom: 30,
  },
  formGroup: {
    marginBottom: 20,
  },
  label: {
    fontSize: 14,
    color: '#aaa',
    marginBottom: 8,
  },
  input: {
    width: '100%',
    padding: 12,
    borderRadius: 10,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    color: '#eee',
    fontSize: 14,
    borderWidth: 1,
    borderColor: 'transparent',
  },
  inputFocused: {
    borderColor: '#58ff7f',
  },
  submitBtn: {
    width: '100%',
    padding: 15,
    marginTop: 10,
    backgroundColor: '#58ff7f',
    borderRadius: 10,
    alignItems: 'center',
    shadowColor: '#58ff7f',
    shadowOffset: {
      width: 0,
      height: 4,
    },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 8,
  },
  submitBtnText: {
    color: '#000',
    fontSize: 16,
    fontWeight: '600',
  },
  formFooter: {
    flexDirection: 'row',
    justifyContent: 'center',
    marginTop: 20,
  },
  footerText: {
    fontSize: 13,
    color: '#aaa',
  },
  footerLink: {
    fontSize: 13,
    color: '#58ff7f',
    fontWeight: '500',
  },
});