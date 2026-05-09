import 'dart:math' as math;

/// Lightweight complex number for quantum state vector arithmetic.
class Complex {
  final double re;
  final double im;

  const Complex(this.re, [this.im = 0.0]);
  const Complex.zero() : re = 0.0, im = 0.0;
  const Complex.one() : re = 1.0, im = 0.0;
  static Complex polar(double magnitude, double phase) =>
      Complex(magnitude * math.cos(phase), magnitude * math.sin(phase));

  double get magnitude => math.sqrt(re * re + im * im);
  double get magnitudeSquared => re * re + im * im;
  double get phase => math.atan2(im, re);
  Complex get conjugate => Complex(re, -im);

  Complex operator +(Complex other) => Complex(re + other.re, im + other.im);
  Complex operator -(Complex other) => Complex(re - other.re, im - other.im);
  Complex operator *(Complex other) =>
      Complex(re * other.re - im * other.im, re * other.im + im * other.re);
  Complex operator /(Complex other) {
    final denom = other.magnitudeSquared;
    return Complex(
      (re * other.re + im * other.im) / denom,
      (im * other.re - re * other.im) / denom,
    );
  }

  Complex operator -() => Complex(-re, -im);
  Complex scale(double s) => Complex(re * s, im * s);

  @override
  String toString() {
    if (im == 0) return re.toStringAsFixed(3);
    if (re == 0) return '${im.toStringAsFixed(3)}i';
    final sign = im >= 0 ? '+' : '-';
    return '${re.toStringAsFixed(3)}$sign${im.abs().toStringAsFixed(3)}i';
  }

  @override
  bool operator ==(Object other) =>
      other is Complex &&
      (re - other.re).abs() < 1e-10 &&
      (im - other.im).abs() < 1e-10;

  @override
  int get hashCode => Object.hash(re.roundToDouble(), im.roundToDouble());
}

/// Common constants.
const Complex cZero = Complex.zero();
const Complex cOne = Complex.one();
final Complex cI = Complex(0, 1);
final Complex cNegOne = Complex(-1, 0);
