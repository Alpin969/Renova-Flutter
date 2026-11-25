/// Keadaan data asinkron yang selalu bisa digambarkan di layar:
/// sedang dimuat, sudah ada isinya, atau gagal dengan pesan yang bisa dibaca.
sealed class Loadable<T> {
  const Loadable();
}

class Loading<T> extends Loadable<T> {
  const Loading();
}

class Ready<T> extends Loadable<T> {
  const Ready(this.data);

  final T data;
}

class Failure<T> extends Loadable<T> {
  const Failure(this.message);

  final String message;
}
