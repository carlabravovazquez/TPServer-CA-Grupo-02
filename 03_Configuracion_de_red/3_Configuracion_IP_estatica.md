# 3. Configuración de IP estática

## Objetivo

Configurar una dirección IP fija en el archivo de configuración de red, dentro del mismo rango que la computadora física, indicando ADDRESS, NETMASK y GATEWAY.

## Conceptos previos

- **Dirección IP:** identifica al equipo en la red. **Máscara de red (netmask):** indica qué parte de la dirección corresponde a la red; `255.255.255.0` equivale a `/24` en notación CIDR, es decir, los tres primeros números identifican la red (`192.168.0.x`). **Gateway (puerta de enlace):** el equipo que conecta la red local con otras redes, en este caso el router (Universidad de Palermo, s. f., *Redes*, pp. 2–4).
- **DHCP** asigna direcciones en forma automática y pueden cambiar. Un servidor necesita una dirección **fija** para que los clientes (SSH, navegador) siempre lo encuentren en el mismo lugar (*DNS-DHCP*, pp. 3–4; *Redes*, p. 5).
- En Debian, la red se configura en **`/etc/network/interfaces`**. `allow-hotplug enp0s3` levanta la interfaz cuando el sistema la detecta, e `iface enp0s3 inet static` indica que se configura en forma manual; los campos van en minúscula: `address`, `netmask`, `gateway` (*Redes*, pp. 4–6; actividad *Configurar IP estática*, p. 1).
- Para que la VM esté en la misma red que la computadora física, el adaptador de VirtualBox debe estar en modo **puente**. Ya lo estaba desde el inicio (se vio en el punto 2.1).

## Procedimiento

### Paso 1: relevamiento (sin cambiar nada)

```bash
ip a
ip route
cat /etc/resolv.conf
cat /etc/network/interfaces
```

| Comando | Resultado | Interpretación |
|---|---|---|
| `ip a` | `inet 192.168.0.209/24 … dynamic … enp0s3` | La IP la asigna DHCP (`dynamic`) |
| `ip route` | `default via 192.168.0.1 dev enp0s3` | El gateway es `192.168.0.1` |
| `cat /etc/resolv.conf` | dos líneas `nameserver` | Servidores DNS del proveedor de internet |
| `cat /etc/network/interfaces` | `allow-hotplug enp0s3` / `iface enp0s3 inet dhcp` | La interfaz está configurada por DHCP |

Fuentes: actividad *Configurar IP estática*, p. 1; *Redes*, pp. 2–6; `/etc` en *El standard FHS*, p. 2.

**Figura 1.** Relevamiento de la configuración de red.

![relevamiento](Capturas/Captura%2003.01.png)

En Windows, `ipconfig` muestra el adaptador Wi-Fi con `192.168.0.34`, máscara `255.255.255.0` y puerta de enlace `192.168.0.1`: **la misma red que la VM**. (El adaptador `Ethernet 2`, con `192.168.56.1`, lo crea VirtualBox para su red "solo anfitrión" y no se usa.)

**Figura 2.** Configuración de red de la computadora física.

![ipconfig](Capturas/Captura%2003.02.png)

**Datos elegidos:**

| Campo | Valor | Motivo |
|---|---|---|
| `address` | `192.168.0.209` | La misma que tenía por DHCP: SSH (2.2) y la web (2.3) siguen en la misma dirección |
| `netmask` | `255.255.255.0` | Igual a la de la computadora física (`/24`) |
| `gateway` | `192.168.0.1` | El router, igual que en Windows |

### Paso 2: configuración

```bash
cp /etc/network/interfaces /etc/network/interfaces.orig
vi /etc/network/interfaces
```

**Figura 3.** Respaldo del archivo.

![cp](Capturas/Captura%2003.03.png)

**Figura 4.** Archivo original en `vi` (`13L, 318B`).

![vi original](Capturas/Captura%2003.04.png)

Teclas en `vi` (*Editores de texto*, pp. 2–4):

| # | Tecla o texto | Qué hace |
|---|---|---|
| 1 | `/dhcp` + Enter | Lleva el cursor a la palabra `dhcp` |
| 2 | `i` → `static` → **Esc** | Escribe `static` delante de `dhcp` |
| 3 | **→** → `x` ×4 | Borra `dhcp` |
| 4 | `a` | Inserta después del cursor (final de la línea) |
| 5 | Enter → `address 192.168.0.209` | Dirección IP |
| 6 | Enter → `netmask 255.255.255.0` | Máscara |
| 7 | Enter → `gateway 192.168.0.1` | Puerta de enlace |
| 8 | **Esc** → `:wq` + Enter | Guarda y sale |

**Figura 5.** Primera edición (con errores de tipeo, ver problema 1).

![vi edición](Capturas/Captura%2003.05.png)

```bash
cat /etc/network/interfaces
shutdown -r now
```

`shutdown -r now` reinicia (`-r`) inmediatamente, para que la red arranque con la configuración nueva (*Comandos*, p. 3; actividad *Configurar IP estática*, pp. 1–2).

**Figura 6.** Archivo guardado (`15L, 382B escritos`) y reinicio.

![cat reinicio](Capturas/Captura%2003.06.png)

### Problema 1: la interfaz no se levantó

```bash
ip a
```

**`enp0s3: <BROADCAST,MULTICAST> … state DOWN`**, sin ninguna dirección IPv4: la VM quedó sin red.

**Figura 7.** Interfaz caída después del reinicio.

![interfaz DOWN](Capturas/Captura%2003.07.png)

**Causa:** dos errores de tipeo en la línea de la dirección: decía `addres` (falta una `s`), una palabra que Debian no reconoce, y `198.168.0.209` en lugar de `192.168.0.209`. Al no poder interpretar la configuración, el sistema no levantó la interfaz.

**Solución:** reescribir la línea completa.

```bash
vi /etc/network/interfaces
```

| # | Tecla o texto | Qué hace |
|---|---|---|
| 1 | `/addres` + Enter | Lleva el cursor a la línea con error |
| 2 | `dd` | Borra la línea completa |
| 3 | `i` → `address 192.168.0.209` → Enter | Escribe la línea correcta |
| 4 | **Esc** → `:wq` + Enter | Guarda y sale |

**Figura 8.** Corrección de la línea.

![corrección](Capturas/Captura%2003.08.png)

```bash
cat /etc/network/interfaces
shutdown -r now
```

`vi` confirmó `15L, 383B escritos`: un byte más que antes, la `s` que faltaba. El final del archivo quedó así:

```text
allow-hotplug enp0s3
iface enp0s3 inet static
address 192.168.0.209
netmask 255.255.255.0
gateway 192.168.0.1
```

**Figura 9.** Archivo corregido y segundo reinicio.

![archivo corregido](Capturas/Captura%2003.09.png)

**Lección:** antes de reiniciar, leer el archivo con `cat` letra por letra. Borrar la línea con `dd` y escribirla completa de nuevo es más seguro que corregir carácter por carácter.

### Paso 3: verificación en la VM

```bash
ip a
```

`enp0s3 … state UP` e **`inet 192.168.0.209/24 brd 192.168.0.255 scope global enp0s3`**. **Ya no dice `dynamic`**: la dirección sale del archivo.

**Figura 10.** Interfaz activa con IP estática.

![ip a](Capturas/Captura%2003.10.png)

```bash
ip route
```

**`default via 192.168.0.1 dev enp0s3 onlink`**. La palabra `onlink` aparece porque ahora el gateway se carga desde el archivo de configuración (antes lo informaba DHCP); indica que el gateway está directamente en la misma red de la interfaz.

**Figura 11.** Ruta por defecto hacia el gateway.

![ip route](Capturas/Captura%2003.11.png)

**Figura 12.** Error de tipeo: `ip route 8.8.8.8` en lugar de `ping 8.8.8.8` (`Command "8.8.8.8" is unknown`).

![ip route error](Capturas/Captura%2003.12.png)

```bash
ping 8.8.8.8
ping deb.debian.org
```

Ambos cortados con **Ctrl + C**: 0 % de pérdida. `deb.debian.org` se resolvió a `151.101.218.132`: **hay internet y el DNS funciona**. No hizo falta configurar DNS porque `/etc/resolv.conf` conservó los servidores DNS del proveedor de internet (actividad *Configurar IP estática*, p. 2; *DNS-DHCP*, p. 1).

**Figura 13.** Conectividad a internet y resolución de nombres.

![ping](Capturas/Captura%2003.13.png)

### Paso 4: verificación desde la computadora física

| Prueba en Windows | Resultado |
|---|---|
| `ping 192.168.0.209` | 4/4 respuestas, 0 % perdidos, `TTL=64` |
| `ssh -i clave_privada.txt root@192.168.0.209` · `exit` | Entra sin contraseña (el punto 2.2 sigue funcionando) |
| Navegador → `http://192.168.0.209` | Tabla de alumnos completa (los puntos 2.3 y 2.4 siguen funcionando) |

**Figura 14.** `ping` desde Windows.

![win ping](Capturas/Captura%2003.14.png)

**Figura 15.** SSH desde Windows con la IP estática.

![win ssh](Capturas/Captura%2003.15.png)

**Figura 16.** Página de alumnos desde Windows.

![win web](Capturas/Captura%2003.16.png)

```bash
history
```

**Figura 17.** `history` del punto 3 (líneas 70–89).

![history](Capturas/Captura%2003.17.png)

Orden real: `ip a` → `ip route` → `cat /etc/resolv.conf` → `cat /etc/network/interfaces` → `cp … .orig` → `vi` → `cat` → `shutdown -r now` → `ip a` (sin IP) → `vi` (corrección) → `cat` → `shutdown -r now` → `ip a` → `ip route` → `ip route 8.8.8.8` (error de tipeo) → `ping 8.8.8.8` → `ip route` → `ping 8.8.8.8` → `ping deb.debian.org` → `history`.

## Problemas encontrados y solución

El problema principal apareció después del primer reinicio: la interfaz `enp0s3` quedó en estado `DOWN` y sin dirección IP, es decir, la máquina se quedó sin red. Al revisar el archivo se encontraron dos errores de tipeo en la misma línea: decía `addres` (faltaba una `s`), una palabra que Debian no reconoce, y la dirección era `198.168.0.209` en lugar de `192.168.0.209`. Como el sistema no pudo interpretar la configuración, no levantó la interfaz. Se resolvió buscando la línea con `/addres`, borrándola completa con `dd` y escribiéndola de nuevo, y se reinició. A partir de este error se adoptó como práctica leer el archivo con `cat` letra por letra antes de reiniciar.

Durante la verificación también se escribió por error `ip route 8.8.8.8` en lugar de `ping 8.8.8.8`, y el sistema respondió `Command "8.8.8.8" is unknown`. Se repitió el comando correctamente.

## Resultado

La VM tiene la dirección fija **`192.168.0.209/24`**, con gateway `192.168.0.1`, configurada en `/etc/network/interfaces`. Tiene acceso a internet y DNS, y sigue respondiendo por SSH y por web desde la computadora física.

**Instantánea de VirtualBox:** `07 - Punto 3 IP estatica`.

## Referencias bibliográficas

- Universidad de Palermo. (s. f.). *Comandos* [Material de cátedra].
- Universidad de Palermo. (s. f.). *Configurar IP estática* [Actividad de cátedra].
- Universidad de Palermo. (s. f.). *DNS-DHCP* [Material de cátedra].
- Universidad de Palermo. (s. f.). *Editores de texto* [Material de cátedra].
- Universidad de Palermo. (s. f.). *El standard FHS* [Material de cátedra].
- Universidad de Palermo. (s. f.). *Redes* [Material de cátedra].
