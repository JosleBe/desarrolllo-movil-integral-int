import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Lenguaje visual de SRUU: cada pantalla es una frase que el usuario
/// completa. La app habla con peso medio; lo que escribe el usuario va en
/// negritas y en otro color, dentro de la misma frase. Cada momento del flujo
/// tiene su color de fondo, y el fondo transita de uno a otro.
enum Scene {
  /// Entrar / inicio.
  mint,

  /// Registrarse / cuenta verificada (verde UTEZ).
  green,

  /// Esperando algo: el correo de verificación, una revisión.
  indigo,

  /// Algo no sirve: enlace vencido, usado o inválido.
  red,
}

@immutable
class SceneColors {
  const SceneColors({
    required this.bg,
    required this.system,
    required this.user,
    required this.noteBg,
    required this.noteFg,
  });

  final Color bg;

  /// Voz de la app.
  final Color system;

  /// Voz del usuario (lo que escribe o lo que es suyo).
  final Color user;

  /// Resaltado de marcador para errores y avisos.
  final Color noteBg;
  final Color noteFg;

  Color get faded => system.withValues(alpha: 0.55);
  Color get barBg => noteBg;
  Color get barFg => noteFg;

  static SceneColors resolve(Scene scene, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return switch ((scene, dark)) {
      (Scene.mint, false) => const SceneColors(
        bg: Color(0xFFE4F1EA),
        system: Color(0xFF0B2B24),
        user: Color(0xFF00785C),
        noteBg: Color(0xFF0B2B24),
        noteFg: Color(0xFFE4F1EA),
      ),
      (Scene.mint, true) => const SceneColors(
        bg: Color(0xFF0D201B),
        system: Color(0xFFDCEFE6),
        user: Color(0xFF4FD7AA),
        noteBg: Color(0xFFDCEFE6),
        noteFg: Color(0xFF0D201B),
      ),
      (Scene.green, false) => const SceneColors(
        bg: Color(0xFF009475),
        system: Color(0xFF03211A),
        user: Color(0xFFFFFFFF),
        noteBg: Color(0xFF03211A),
        noteFg: Color(0xFFFFFFFF),
      ),
      (Scene.green, true) => const SceneColors(
        bg: Color(0xFF00483B),
        system: Color(0xFFC9EBDD),
        user: Color(0xFFFFFFFF),
        noteBg: Color(0xFFC9EBDD),
        noteFg: Color(0xFF00483B),
      ),
      (Scene.indigo, false) => const SceneColors(
        bg: Color(0xFF2F2A80),
        system: Color(0xFFF0EEFF),
        user: Color(0xFFA6F3D3),
        noteBg: Color(0xFFF0EEFF),
        noteFg: Color(0xFF2F2A80),
      ),
      (Scene.indigo, true) => const SceneColors(
        bg: Color(0xFF17153F),
        system: Color(0xFFE4E1FF),
        user: Color(0xFFA6F3D3),
        noteBg: Color(0xFFE4E1FF),
        noteFg: Color(0xFF17153F),
      ),
      (Scene.red, false) => const SceneColors(
        bg: Color(0xFFC42B38),
        system: Color(0xFFFFFFFF),
        user: Color(0xFFFFE08A),
        noteBg: Color(0xFFFFFFFF),
        noteFg: Color(0xFFC42B38),
      ),
      (Scene.red, true) => const SceneColors(
        bg: Color(0xFF5E1119),
        system: Color(0xFFFFE7E9),
        user: Color(0xFFFFD27A),
        noteBg: Color(0xFFFFE7E9),
        noteFg: Color(0xFF5E1119),
      ),
    };
  }
}

/// Colores y tamaños de la frase disponibles para los widgets hijos.
class SceneStyle extends InheritedWidget {
  const SceneStyle({
    super.key,
    required this.colors,
    required this.size,
    required this.wide,
    required super.child,
  });

  final SceneColors colors;

  /// Tamaño de la frase principal (depende del ancho de pantalla).
  final double size;
  final bool wide;

  static SceneStyle of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SceneStyle>()!;

  TextStyle get systemVoice =>
      AppTheme.display(size, weight: 520, color: colors.system);

  TextStyle get userVoice =>
      AppTheme.display(size, weight: 800, color: colors.user);

  TextStyle get body => TextStyle(
    fontFamily: AppTheme.bodyFamily,
    fontSize: wide ? 19 : 17,
    height: 1.45,
    color: colors.system,
  );

  TextStyle get note => TextStyle(
    fontFamily: AppTheme.bodyFamily,
    fontSize: wide ? 18 : 16,
    height: 1.6,
    fontWeight: FontWeight.w700,
    color: colors.noteFg,
    backgroundColor: colors.noteBg,
  );

  @override
  bool updateShouldNotify(SceneStyle old) =>
      old.colors != colors || old.size != size || old.wide != wide;
}

/// Recuerda el último color de fondo para que la siguiente pantalla
/// transite desde él.
abstract final class _SceneMemory {
  static Color? lastBg;
}

/// Esqueleto de todas las pantallas: marca arriba, frase al centro-izquierda
/// y la acción principal como barra a todo lo ancho abajo.
class SentenceScaffold extends StatefulWidget {
  const SentenceScaffold({
    super.key,
    required this.scene,
    required this.children,
    this.topAction,
    this.action,
    this.busy = false,
  });

  final Scene scene;
  final List<Widget> children;
  final Widget? topAction;
  final ActionBar? action;

  /// Muestra una barra de progreso fina arriba.
  final bool busy;

  @override
  State<SentenceScaffold> createState() => _SentenceScaffoldState();
}

class _SentenceScaffoldState extends State<SentenceScaffold> {
  Color? _from;

  @override
  void initState() {
    super.initState();
    _from = _SceneMemory.lastBg;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = SceneColors.resolve(widget.scene, brightness);
    _SceneMemory.lastBg = colors.bg;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final wide = width >= 720;
        final size = width >= 1100 ? 66.0 : (wide ? 52.0 : 34.0);
        final gutter = width >= 1100 ? 96.0 : (wide ? 56.0 : 22.0);

        final content = SceneStyle(
          colors: colors,
          size: size,
          wide: wide,
          child: Theme(
            data: Theme.of(context).copyWith(
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: colors.user,
                selectionColor: colors.user.withValues(alpha: 0.3),
                selectionHandleColor: colors.user,
              ),
              iconTheme: IconThemeData(color: colors.system),
              progressIndicatorTheme: ProgressIndicatorThemeData(
                color: colors.user,
                linearTrackColor: Colors.transparent,
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 3,
                  child: widget.busy
                      ? const LinearProgressIndicator(minHeight: 3)
                      : null,
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(gutter, 14, gutter - 8, 0),
                    child: Row(
                      children: [
                        const Wordmark(),
                        const Spacer(),
                        ?widget.topAction,
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      gutter,
                      wide ? 72 : 36,
                      gutter,
                      40,
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: wide ? 860 : 520),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: widget.children,
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.action != null)
                  _ActionGutter(gutter: gutter, child: widget.action!),
              ],
            ),
          ),
        );

        return TweenAnimationBuilder<Color?>(
          tween: ColorTween(begin: _from ?? colors.bg, end: colors.bg),
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 520),
          curve: Curves.easeInOutCubic,
          builder: (context, bg, child) =>
              AnnotatedRegion<SystemUiOverlayStyle>(
                value:
                    ThemeData.estimateBrightnessForColor(colors.bg) ==
                        Brightness.dark
                    ? SystemUiOverlayStyle.light
                    : SystemUiOverlayStyle.dark,
                child: Scaffold(backgroundColor: bg, body: child),
              ),
          child: content,
        );
      },
    );
  }
}

class _ActionGutter extends InheritedWidget {
  const _ActionGutter({required this.gutter, required super.child});
  final double gutter;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ActionGutter>()?.gutter ?? 22;

  @override
  bool updateShouldNotify(_ActionGutter old) => old.gutter != gutter;
}

/// Acción principal: barra a todo lo ancho, pegada abajo (y sobre el teclado).
class ActionBar extends StatelessWidget {
  const ActionBar({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.busyLabel,
  });

  final String label;
  final String? busyLabel;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final style = SceneStyle.of(context);
    final gutter = _ActionGutter.of(context);
    final c = style.colors;

    return Semantics(
      button: true,
      enabled: !busy,
      label: busy ? (busyLabel ?? label) : label,
      excludeSemantics: true,
      child: Material(
        color: c.barBg,
        child: InkWell(
          onTap: busy ? null : onPressed,
          focusColor: c.barFg.withValues(alpha: 0.16),
          hoverColor: c.barFg.withValues(alpha: 0.06),
          splashColor: c.barFg.withValues(alpha: 0.12),
          child: SafeArea(
            top: false,
            child: Container(
              height: style.wide ? 84 : 68,
              padding: EdgeInsets.symmetric(horizontal: gutter),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      busy ? (busyLabel ?? label) : label,
                      style: AppTheme.display(
                        style.wide ? 28 : 22,
                        weight: 700,
                        color: c.barFg,
                      ),
                    ),
                  ),
                  if (busy)
                    SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: c.barFg,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Una línea de la frase en voz de la app. Con [Say.rich], los fragmentos
/// creados con [you] se pintan en la voz del usuario.
class Say extends StatelessWidget {
  const Say(this.text, {super.key}) : spans = null;
  const Say.rich(this.spans, {super.key}) : text = null;

  final String? text;
  final List<InlineSpan>? spans;

  @override
  Widget build(BuildContext context) {
    final style = SceneStyle.of(context);
    return Text.rich(
      TextSpan(
        text: text,
        children: spans
            ?.map(
              (s) => s is TextSpan && identical(s.style, _youMarker)
                  ? TextSpan(text: s.text, style: style.userVoice)
                  : s,
            )
            .toList(),
      ),
      style: style.systemVoice,
    );
  }
}

const _youMarker = TextStyle(debugLabel: 'sruu.you');

/// Fragmento en voz del usuario dentro de [Say.rich].
TextSpan you(String text) => TextSpan(text: text, style: _youMarker);

/// Texto de apoyo, más chico, debajo de la frase.
class Aside extends StatelessWidget {
  const Aside(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final style = SceneStyle.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Text(text, style: style.body),
    );
  }
}

/// Aviso con resaltado de marcador (errores o confirmaciones).
class Note extends StatelessWidget {
  const Note(this.text, {super.key, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final style = SceneStyle.of(context);
    return Semantics(
      liveRegion: true,
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(' $text ', style: style.note),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Enlace de texto subrayado en voz de la app (acciones secundarias).
class TextLink extends StatelessWidget {
  const TextLink(this.label, {super.key, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = SceneStyle.of(context);
    final color = onPressed == null ? style.colors.faded : style.colors.system;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        disabledForegroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
        minimumSize: const Size(0, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        alignment: Alignment.centerLeft,
        overlayColor: style.colors.system,
      ),
      child: Text(
        label,
        style: style.body.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
          decorationColor: color,
          decorationThickness: 2,
        ),
      ),
    );
  }
}

/// Campo escrito dentro de la frase, con la misma tipografía enorme.
class SentenceField extends StatelessWidget {
  const SentenceField({
    super.key,
    required this.controller,
    required this.hint,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onSubmitted,
    this.suffix,
    this.autofocus = false,
    this.scale = 1,
    this.forceError = false,
  });

  final TextEditingController controller;
  final String hint;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  final bool autofocus;

  /// Tamaño relativo a la frase (p. ej. 0.55 para pegar un enlace largo).
  final double scale;

  /// Pinta la línea en estado de error (cuando la validación vive afuera).
  final bool forceError;

  @override
  Widget build(BuildContext context) {
    final style = SceneStyle.of(context);
    final c = style.colors;
    final voice = style.userVoice.copyWith(fontSize: style.size * scale);
    UnderlineInputBorder line(Color color) =>
        UnderlineInputBorder(borderSide: BorderSide(color: color, width: 3));

    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      obscuringCharacter: '•',
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      autocorrect: false,
      enableSuggestions: !obscureText,
      autofocus: autofocus,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      style: voice,
      cursorColor: c.user,
      cursorWidth: 3,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: voice.copyWith(
          color: c.faded,
          fontVariations: const [FontVariation.weight(500)],
        ),
        suffixIcon: suffix,
        isDense: true,
        filled: false,
        contentPadding: const EdgeInsets.only(top: 4, bottom: 8),
        enabledBorder: line(forceError ? c.noteBg : c.faded),
        focusedBorder: line(forceError ? c.noteBg : c.user),
        errorBorder: line(c.noteBg),
        focusedErrorBorder: line(c.noteBg),
        errorStyle: style.note,
        errorMaxLines: 4,
      ),
    );
  }
}

/// Correo institucional: el usuario escribe solo su matrícula o usuario y el
/// dominio @utez.edu.mx forma parte fija de la frase.
class MatriculaField extends StatelessWidget {
  const MatriculaField({
    super.key,
    required this.controller,
    required this.validator,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.autofocus = false,
  });

  static const domain = '@utez.edu.mx';

  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  void _stripDomain(String value) {
    final lower = value.toLowerCase();
    if (lower.endsWith(domain) && lower.length > domain.length) {
      final local = value.substring(0, value.length - domain.length);
      controller.value = TextEditingValue(
        text: local,
        selection: TextSelection.collapsed(offset: local.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = SceneStyle.of(context);

    // La validación vive en este FormField para que el error aparezca
    // después del dominio, no entre la matrícula y el dominio.
    return FormField<String>(
      validator: (_) => validator(controller.text),
      builder: (state) {
        final input = SentenceField(
          controller: controller,
          hint: 'matrícula',
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.username, AutofillHints.email],
          textInputAction: textInputAction,
          onChanged: (value) {
            _stripDomain(value);
            state.didChange(controller.text);
          },
          onSubmitted: onSubmitted,
          autofocus: autofocus,
          forceError: state.hasError,
        );

        final line = style.wide
            // En pantallas anchas el dominio va pegado a lo que escribes.
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: style.size * 3),
                      child: IntrinsicWidth(child: input),
                    ),
                  ),
                  const Say(domain),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [input, const SizedBox(height: 4), const Say(domain)],
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            line,
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Semantics(
                  liveRegion: true,
                  child: Text(state.errorText!, style: style.note),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Contraseña en la frase, con botón para mostrarla.
class PasswordSentenceField extends StatefulWidget {
  const PasswordSentenceField({
    super.key,
    required this.controller,
    this.hint = 'tu clave',
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction = TextInputAction.done,
    this.autofillHints = const [AutofillHints.password],
  });

  final TextEditingController controller;
  final String hint;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction textInputAction;
  final Iterable<String> autofillHints;

  @override
  State<PasswordSentenceField> createState() => _PasswordSentenceFieldState();
}

class _PasswordSentenceFieldState extends State<PasswordSentenceField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    final c = SceneStyle.of(context).colors;
    return SentenceField(
      controller: widget.controller,
      hint: widget.hint,
      obscureText: _hidden,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      suffix: IconButton(
        tooltip: _hidden ? 'Mostrar clave' : 'Ocultar clave',
        color: c.system,
        icon: Icon(
          _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
        onPressed: () => setState(() => _hidden = !_hidden),
      ),
    );
  }
}

/// Marca: "sruu" en minúsculas, sin adornos.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key});

  @override
  Widget build(BuildContext context) {
    final style = SceneStyle.of(context);
    return Semantics(
      label: 'SRUU',
      excludeSemantics: true,
      child: Text(
        'sruu',
        style: AppTheme.display(
          style.wide ? 30 : 26,
          weight: 820,
          color: style.colors.system,
        ),
      ),
    );
  }
}

/// Espacio vertical proporcional al tamaño de la frase.
class Gap extends StatelessWidget {
  const Gap(this.lines, {super.key});
  final double lines;

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: SceneStyle.of(context).size * 0.5 * lines);
}
