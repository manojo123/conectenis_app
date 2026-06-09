# Backend prompt — ViaCEP / endereço do usuário

Copie e cole no chat do projeto Laravel `conectenis`:

```
Implementar consulta de CEP via ViaCEP no backend e expandir campos de endereço do usuário.

CONTEXTO
- App Flutter (conectenis_app) já consome GET /api/address/postal-code/{cep} e envia novos campos no PUT /user/profile.
- O app NÃO chama ViaCEP diretamente — toda lógica fica no Laravel.
- API ViaCEP: https://viacep.com.br/ws/{cep}/json/ (retorna {"erro": true} se CEP inexistente).

TAREFAS

1) ENDPOINT PÚBLICO DE CEP
- Rota: GET /api/address/postal-code/{postalCode}
- Aceitar CEP com ou sem hífen; normalizar para 8 dígitos.
- Validar formato (422 se inválido).
- Chamar ViaCEP server-side (Http::get ou serviço dedicado).
- Cachear resposta por CEP (Cache::remember, TTL 7 dias) para reduzir chamadas externas.
- Resposta 200 JSON normalizado:

{
  "postal_code": "01310-100",
  "street": "Avenida Paulista",
  "neighborhood": "Bela Vista",
  "city": "São Paulo",
  "state": "SP",
  "state_name": "São Paulo",
  "country": "BR",
  "complement_hint": "de 612 a 1510 - lado par",
  "ibge": "3550308",
  "ddd": "11"
}

- 404 se ViaCEP retornar erro ou CEP inexistente.
- Mapeamento ViaCEP → API:
  - cep → postal_code (formatado #####-###)
  - logradouro → street
  - bairro → neighborhood
  - localidade → city
  - uf → state
  - estado → state_name
  - complemento → complement_hint (somente sugestão; usuário edita no app)

2) MIGRATION users — novos campos
- neighborhood (string, nullable)
- address_number (string, nullable, max 20)
- address_complement (string, nullable, max 120)
- Garantir postal_code já existe (nullable)

3) MODEL + RESOURCE
- User $fillable: neighborhood, address_number, address_complement
- UserResource expor: neighborhood, address_number, address_complement, postal_code, address_line, city, state, country

4) UpdateProfileRequest
- Validar:
  - postal_code: sometimes, string, max 20
  - address_line: logradouro (sometimes, string, max 255) — NÃO concatenar número aqui
  - address_number: sometimes, string, max 20
  - address_complement: sometimes, nullable, string, max 120
  - neighborhood: sometimes, string, max 120
  - city, state, country: regras existentes

5) ProfileController@update
- Persistir novos campos; manter CityResolver ao atualizar city/state/country.

6) TESTES (Pest)
- GET /api/address/postal-code/01310100 → 200 com street/city/state (Http::fake ViaCEP).
- CEP inválido → 422.
- CEP inexistente → 404.
- PUT /user/profile com postal_code + address_line + address_number + neighborhood → salva e retorna no UserResource.

7) DOCS
- Atualizar docs/API.md com seção Address lookup e novos campos de perfil.

REFERÊNCIAS NO REPO
- app/Http/Controllers/Api/ProfileController.php
- app/Http/Requests/UpdateProfileRequest.php
- app/Http/Resources/UserResource.php
- app/Models/User.php
- routes/api.php
```
