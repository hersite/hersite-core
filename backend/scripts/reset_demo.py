import subprocess
import sys


def main():
    print("Reiniciando datos demo...")
    print("Paso 1/2: limpiando datos demo existentes.")

    subprocess.check_call(
        [sys.executable, "scripts/clear_demo.py"],
    )

    print("Paso 2/2: cargando datos demo nuevamente.")

    subprocess.check_call(
        [sys.executable, "scripts/seed_demo.py"],
    )

    print("Reset demo finalizado correctamente.")


if __name__ == "__main__":
    main()