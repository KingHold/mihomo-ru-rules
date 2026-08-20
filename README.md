# mihomo-ru-rules

Автоматически обновляемый MRS rule-set со всеми известными заблокированными в России доменами из RunetFreedom.

## Готовый rule-set

Стабильный raw-адрес:

```text
https://raw.githubusercontent.com/KingHold/mihomo-ru-rules/main/ru-blocked-all.mrs
```

Пример подключения в Mihomo:

```yaml
rule-providers:
  ru-blocked-all:
    type: http
    behavior: domain
    format: mrs
    url: "https://raw.githubusercontent.com/KingHold/mihomo-ru-rules/main/ru-blocked-all.mrs"
    path: ./rule_providers/ru-blocked-all.mrs
    interval: 21600
    proxy: DIRECT

rules:
  - RULE-SET,ru-blocked-all,VPN-AUTO
```

Полный обезличенный пример для MikroTik/Mihomo: [`examples/config.yaml`](examples/config.yaml). Перед использованием замените `CHANGE_ME_STRONG_SECRET`, URL подписки BlancVPN и при необходимости локальные подсети.

## Автоматическая сборка

GitHub Actions запускает `scripts/build.sh` примерно раз в 6 часов. Скрипт:

1. загружает свежий `ru-blocked-all.txt` из release-ветки `runetfreedom/russia-blocked-geosite`;
2. загружает последнюю стабильную официальную сборку `MetaCubeX/mihomo` для Linux amd64;
3. проверяет SHA-256 архива, когда GitHub публикует digest;
4. выполняет `mihomo convert-ruleset domain text`;
5. обновляет `ru-blocked-all.mrs` только при изменении результата.

Расписание GitHub Actions не гарантирует запуск минута в минуту и при нагрузке может задерживаться.

## Источники

- [RunetFreedom russia-blocked-geosite](https://github.com/runetfreedom/russia-blocked-geosite)
- [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo)
- [Документация Mihomo по rule-providers](https://wiki.metacubex.one/en/config/rule-providers/)

