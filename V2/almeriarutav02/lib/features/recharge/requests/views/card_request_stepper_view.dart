import 'package:flutter/material.dart';

import '../models/card_request_info.dart';
import '../models/card_request_submission.dart';
import '../services/card_request_service.dart';

class CardRequestStepperView extends StatefulWidget {
  final CardRequestInfo info;
  final String? token;

  const CardRequestStepperView({
    super.key,
    required this.info,
    required this.token,
  });

  @override
  State<CardRequestStepperView> createState() => _CardRequestStepperViewState();
}

class _CardRequestStepperViewState extends State<CardRequestStepperView> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _submitting = false;

  final _fullName = TextEditingController();
  final _dni = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();
  bool _acceptConditions = false;
  final Map<String, bool> _documentChecks = {};

  @override
  void dispose() {
    _fullName.dispose();
    _dni.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = widget.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesion para solicitar tarjetas.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptConditions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes aceptar las condiciones.')),
      );
      return;
    }

    setState(() => _submitting = true);

    final documentsProvided = _documentChecks.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    final submission = CardRequestSubmission(
      cardId: widget.info.id,
      fullName: _fullName.text.trim(),
      dni: _dni.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      extraNotes: _notes.text.trim(),
      documentsProvided: documentsProvided,
      createdAt: DateTime.now(),
    );

    await CardRequestService().submit(token: token, submission: submission);

    if (!mounted) return;
    setState(() => _submitting = false);

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Solicitud enviada'),
        content: const Text(
          'Tu solicitud se ha enviado. Un operario revisara los datos y recibiras una notificacion con la respuesta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    ).then((_) {
      if (!mounted) return;
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;

    return Scaffold(
      appBar: AppBar(
        title: Text(info.title),
        backgroundColor: const Color(0xFFB42318),
        foregroundColor: Colors.white,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 4) {
            setState(() => _currentStep += 1);
          } else {
            _submit();
          }
        },
        onStepCancel: () {
          if (_currentStep == 0) {
            Navigator.pop(context);
          } else {
            setState(() => _currentStep -= 1);
          }
        },
        controlsBuilder: (context, details) {
          return Row(
            children: [
              ElevatedButton(
                onPressed: _submitting ? null : details.onStepContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB42318),
                  foregroundColor: Colors.white,
                ),
                child: Text(_currentStep < 4 ? 'Continuar' : 'Enviar solicitud'),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: _submitting ? null : details.onStepCancel,
                child: const Text('Atras'),
              ),
            ],
          );
        },
        steps: [
          Step(
            title: const Text('Resumen'),
            content: _buildSummary(info),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text('Requisitos'),
            content: _buildList(info.requirements, emptyText: 'Sin requisitos especiales.'),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: const Text('Documentacion'),
            content: _buildDocuments(info),
            isActive: _currentStep >= 2,
          ),
          Step(
            title: const Text('Donde presentar'),
            content: _buildList(info.whereToSubmit, emptyText: 'Consulta oficina SURBUS.'),
            isActive: _currentStep >= 3,
          ),
          Step(
            title: const Text('Solicitud'),
            content: _buildForm(info),
            isActive: _currentStep >= 4,
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(CardRequestInfo info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(info.shortDescription, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Precio: ${info.priceLabel}'),
        Text('Tramitacion: ${info.acquisition}'),
        if (info.extraInfo.isNotEmpty) Text(info.extraInfo),
        const SizedBox(height: 12),
        _buildList(info.details, emptyText: 'Sin detalles extra.'),
        const SizedBox(height: 12),
        _buildList(info.conditions, emptyText: 'Condiciones no disponibles.'),
      ],
    );
  }

  Widget _buildForm(CardRequestInfo info) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _fullName,
            decoration: const InputDecoration(labelText: 'Nombre completo'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
          ),
          TextFormField(
            controller: _dni,
            decoration: const InputDecoration(labelText: 'DNI'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
          ),
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
          ),
          TextFormField(
            controller: _phone,
            decoration: const InputDecoration(labelText: 'Telefono'),
            keyboardType: TextInputType.phone,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
          ),
          TextFormField(
            controller: _address,
            decoration: const InputDecoration(labelText: 'Direccion'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
          ),
          TextFormField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Notas adicionales (opcional)'),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _acceptConditions,
            onChanged: (value) => setState(() => _acceptConditions = value ?? false),
            title: const Text('Acepto las condiciones de uso y normativa vigente'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (_submitting) const Padding(
            padding: EdgeInsets.only(top: 12),
            child: CircularProgressIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildDocuments(CardRequestInfo info) {
    if (info.documents.isEmpty) {
      return const Text('Sin documentos extra.', style: TextStyle(color: Colors.grey));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Marca los documentos que vas a adjuntar (mock):',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...info.documents.map(
          (doc) => CheckboxListTile(
            value: _documentChecks[doc] ?? false,
            onChanged: (value) => setState(() {
              _documentChecks[doc] = value ?? false;
            }),
            title: Text(doc),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<String> items, {required String emptyText}) {
    if (items.isEmpty) {
      return Text(emptyText, style: const TextStyle(color: Colors.grey));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
