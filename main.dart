import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Formulario Accesible',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AccessibleFormScreen(),
    );
  }
}

class AccessibleFormScreen extends StatefulWidget {
  @override
  _AccessibleFormScreenState createState() => _AccessibleFormScreenState();
}

class _AccessibleFormScreenState extends State<AccessibleFormScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final _formKey = GlobalKey<FormState>();

  // Controladores
  TextEditingController _nombreController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _telefonoController = TextEditingController();
  TextEditingController _mensajeController = TextEditingController();

  String _selectedOption = 'Opción 1';
  bool _aceptoTerminos = false;

  // 🔊 Variables de reconocimiento de voz
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastWords = "";

  @override
  void initState() {
    super.initState();
    _initTts();
    _speech = stt.SpeechToText();
  }

  _initTts() async {
    await flutterTts.setLanguage("es-ES");
    await flutterTts.setSpeechRate(1.0);
    await flutterTts.setVolume(5.0);
  }

  _speak(String text) async {
    if (text.isNotEmpty) {
      await flutterTts.speak(text);
    }
  }

  _readFieldDescription(String fieldName, String description) {
    _speak("Campo $fieldName. $description");
  }

  _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (!_aceptoTerminos) {
        _speak("Debe aceptar los términos y condiciones");
        return;
      }
      _speak("Formulario enviado correctamente. Gracias por registrarse");
    } else {
      _speak("Por favor, corrija los errores en el formulario");
    }
  }

  // 🎤 Escuchar y llenar campo con voz (mejorado)
  void _listen(TextEditingController controller, {bool isEmail = false}) async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done') {
            setState(() {
              _isListening = false;
            });
          }
        },
        onError: (val) => print('Error: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        await _speech.listen(
          localeId: "es_ES",
          onResult: (val) {
            setState(() {
              _lastWords = val.recognizedWords;
              String texto = _lastWords;

              // 🔄 Reemplazo de palabras por símbolos
              if (isEmail) {
                texto = texto
                    .replaceAll(RegExp(r'\barroba\b', caseSensitive: false), '@')
                    .replaceAll(RegExp(r'\bpunto com\b', caseSensitive: false), '.com')
                    .replaceAll(RegExp(r'\bpunto co\b', caseSensitive: false), '.co')
                    .replaceAll(RegExp(r'\bpunto es\b', caseSensitive: false), '.es')
                    .replaceAll(RegExp(r'\bpunto net\b', caseSensitive: false), '.net')
                    .replaceAll(RegExp(r'\bpunto\b', caseSensitive: false), '.')
                    .replaceAll(RegExp(r'\bguion bajo\b', caseSensitive: false), '_')
                    .replaceAll(RegExp(r'\bguion\b', caseSensitive: false), '-');

                // 🚫 Eliminar todos los espacios en correos
                texto = texto.replaceAll(' ', '');
              }

              controller.text = texto;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      await _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FORMULARIO ACCESIBLE'),
        actions: [
          IconButton(
            icon: Icon(Icons.volume_up),
            onPressed: () => _speak("Formulario de registro. Complete todos los campos marcados como requeridos"),
            tooltip: 'Leer instrucciones',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Complete el formulario:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.record_voice_over),
                    onPressed: () => _speak("Formulario de registro. Complete todos los campos marcados con asterisco"),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Campo Nombre
              _buildTextFieldWithSpeech(
                controller: _nombreController,
                label: 'Nombre completo *',
                hint: 'Ingrese su nombre completo',
                fieldName: 'Nombre completo',
                description: 'Requerido. Escriba su nombre y apellido',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su nombre';
                  }
                  return null;
                },
              ),
              SizedBox(height: 15),

              // Campo Email
              _buildTextFieldWithSpeech(
                controller: _emailController,
                label: 'Correo electrónico *',
                hint: 'ejemplo@correo.com',
                fieldName: 'Correo electrónico',
                description: 'Requerido. Ingrese un email válido',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su email';
                  }
                  if (!value.contains('@')) {
                    return 'Ingrese un email válido';
                  }
                  return null;
                },
              ),
              SizedBox(height: 15),

              // Campo Teléfono
              _buildTextFieldWithSpeech(
                controller: _telefonoController,
                label: 'Teléfono',
                hint: '+57 300 123 4567',
                fieldName: 'Teléfono',
                description: 'Opcional. Ingrese su número de contacto',
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 15),

              _buildDropdownWithSpeech(),
              SizedBox(height: 15),

              // Campo Mensaje
              _buildTextFieldWithSpeech(
                controller: _mensajeController,
                label: 'Mensaje o comentarios',
                hint: 'Escriba su mensaje aquí...',
                fieldName: 'Mensaje',
                description: 'Opcional. Escriba cualquier comentario adicional',
                maxLines: 4,
              ),
              SizedBox(height: 20),

              _buildCheckboxWithSpeech(),
              SizedBox(height: 30),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _submitForm,
                      icon: Icon(Icons.send),
                      label: Text('ENVIAR FORMULARIO'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  IconButton(
                    icon: Icon(Icons.volume_up),
                    onPressed: () => _speak("Botón enviar formulario. Presione para enviar la información"),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              Center(
                child: OutlinedButton.icon(
                  onPressed: () => _readFormSummary(),
                  icon: Icon(Icons.audio_file),
                  label: Text('LEER RESUMEN DEL FORMULARIO'),
                ),
              ),

              SizedBox(height: 20),

              // 🔴 Botón global para dictar
              Center(
                child: OutlinedButton.icon(
                  onPressed: () => _listen(_mensajeController),
                  icon: Icon(Icons.mic, color: Colors.red),
                  label: Text('DICTAR FORMULARIO COMPLETO'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFieldWithSpeech({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String fieldName,
    required String description,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: Icon(Icons.mic, size: 18, color: Colors.redAccent),
              onPressed: () => _listen(controller, isEmail: fieldName.toLowerCase().contains('correo')),
              tooltip: 'Dictar con voz',
            ),
            IconButton(
                                  icon: Icon(Icons.record_voice_over,size:18),
              onPressed: () => _readFieldDescription(fieldName, description),
              tooltip: 'Leer descripción',
            ),
          ],
        ),
        SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(12),
          ),
          onTap: () => _readFieldDescription(fieldName, description),
        ),
      ],
    );
  }

  Widget _buildDropdownWithSpeech() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tipo de consulta *',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
                                  icon: Icon(Icons.record_voice_over,size:18),
              onPressed: () => _speak("Tipo de consulta. Seleccione una opción del menú desplegable"),
              tooltip: 'Leer descripción',
            ),
          ],
        ),
        SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: _selectedOption,
          items: ['Opción 1', 'Opción 2', 'Opción 3', 'Opción 4'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedOption = newValue!;
            });
            _speak("Seleccionado: $newValue");
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxWithSpeech() {
    return Row(
      children: [
        Checkbox(
          value: _aceptoTerminos,
          onChanged: (bool? value) {
            setState(() {
              _aceptoTerminos = value!;
            });
            _speak(value! ? "Términos aceptados" : "Términos no aceptados");
          },
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _aceptoTerminos = !_aceptoTerminos;
              });
              _speak(_aceptoTerminos ? "Términos aceptados" : "Términos no aceptados");
            },
            child: Text(
              'Acepto los términos y condiciones *',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        IconButton(
                                  icon: Icon(Icons.record_voice_over,size:18),
          onPressed: () => _speak("Debe aceptar los términos y condiciones para continuar"),
          tooltip: 'Leer descripción',
        ),
      ],
    );
  }

  void _readFormSummary() {
    String summary = """
      Resumen del formulario.
      Nombre: ${_nombreController.text.isEmpty ? 'No ingresado' : _nombreController.text}.
      Email: ${_emailController.text.isEmpty ? 'No ingresado' : _emailController.text}.
      Teléfono: ${_telefonoController.text.isEmpty ? 'No ingresado' : _telefonoController.text}.
      Tipo de consulta: $_selectedOption.
      Mensaje: ${_mensajeController.text.isEmpty ? 'No ingresado' : _mensajeController.text}.
      Términos: ${_aceptoTerminos ? 'Aceptados' : 'No aceptados'}.
    """;
    _speak(summary);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _mensajeController.dispose();
    flutterTts.stop();
    super.dispose();
  }
}