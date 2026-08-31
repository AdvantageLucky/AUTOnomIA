/// Envuelve una función de carga costosa (async) para que solo se ejecute
/// una vez: la primera llamada a [obtener] dispara la carga real; llamadas
/// posteriores -- incluso si la primera todavía no terminó -- reciben el
/// mismo Future en vez de disparar una segunda carga en paralelo.
class CargaUnica<T> {
  CargaUnica(this._cargador);

  final Future<T> Function() _cargador;
  T? _valor;
  Future<T>? _cargaEnCurso;

  Future<T> obtener() {
    final valor = _valor;
    if (valor != null) return Future.value(valor);

    final enCurso = _cargaEnCurso;
    if (enCurso != null) return enCurso;

    final future = _cargador().then((v) {
      _valor = v;
      _cargaEnCurso = null;
      return v;
    });
    _cargaEnCurso = future;
    return future;
  }
}
