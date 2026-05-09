import 'dart:math' as math;
import '../utils/complex.dart';

/// Bloch sphere coordinates for a single-qubit state.
class BlochCoords {
  /// Cartesian coordinates on the Bloch sphere.
  final double x, y, z;

  /// Spherical coordinates: theta (polar), phi (azimuthal).
  final double theta, phi;

  const BlochCoords({
    required this.x,
    required this.y,
    required this.z,
    required this.theta,
    required this.phi,
  });

  /// Compute Bloch coordinates from a single-qubit state |ψ⟩ = α|0⟩ + β|1⟩.
  ///
  /// θ = 2 * arccos(|α|)
  /// φ = arg(β) - arg(α)
  /// x = sin(θ)cos(φ), y = sin(θ)sin(φ), z = cos(θ)
  factory BlochCoords.fromState(Complex alpha, Complex beta) {
    final alphaMag = alpha.magnitude;
    final betaMag = beta.magnitude;

    // Normalize
    final norm = math.sqrt(alphaMag * alphaMag + betaMag * betaMag);
    if (norm < 1e-15) {
      return const BlochCoords(x: 0, y: 0, z: 1, theta: 0, phi: 0);
    }

    final aNorm = alphaMag / norm;
    final theta = 2.0 * math.acos(aNorm.clamp(0.0, 1.0));
    final phi = beta.phase - alpha.phase;

    final sinTheta = math.sin(theta);
    return BlochCoords(
      x: sinTheta * math.cos(phi),
      y: sinTheta * math.sin(phi),
      z: math.cos(theta),
      theta: theta,
      phi: phi,
    );
  }

  /// |0⟩ state — north pole.
  static const northPole = BlochCoords(x: 0, y: 0, z: 1, theta: 0, phi: 0);

  /// |1⟩ state — south pole.
  static const southPole =
      BlochCoords(x: 0, y: 0, z: -1, theta: math.pi, phi: 0);

  @override
  String toString() =>
      'Bloch(x=${x.toStringAsFixed(3)}, y=${y.toStringAsFixed(3)}, z=${z.toStringAsFixed(3)})';
}
