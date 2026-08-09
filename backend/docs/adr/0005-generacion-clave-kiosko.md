# 0005 - Generación de clave de Kiosko para registro de Kioskos

## Status
Superseded by [0019](0019-activacion-kiosko-device-authorization-grant.md)

> La `ClaveKiosko` sigue existiendo como credencial interna de re-autenticación del kiosko. Lo que
> queda reemplazado es su entrega manual: el admin ya no la copia ni la transcribe al dispositivo.

## Context
El Administrador debe tener una forma de registrar un Kiosko a su cuenta cuando lo haya adquirido:

- Primero el admin debe tener una **cuenta de Administrador** (posiblemente conectada con el ecosistema existente de Kigo). Esta se crea en el panel de admin.

## Decision
Dentro del panel Admin el Administrador **registra un Kiosko/Kiosko y retorna su id y su ClaveKiosko para activar el Kiosko**. El admin ingresa dicha información al Kiosko para activarlo y finalmente ya usarlo.


## Consequences
El kiosko tendrá una primera interfaz donde indique al Administrador como registrar este Kiosko. La pantalla puede apuntar a la pagina web para que también el Administrador haga su cuenta de Admin. Se le debe dar instrucciones claras de como registrar el Kiosko y posiblemente hacer su cuenta de Administrador.
