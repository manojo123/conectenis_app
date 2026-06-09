# Backend prompt — Avatar (Gravatar + storage / S3)

Copie e cole no projeto Laravel `conectenis`:

```
Implementar avatar com Gravatar por padrão e upload customizado gerenciado pelo backend (local storage agora, S3 depois).

CONTEXTO
- App Flutter já envia POST /api/user/avatar (multipart) e DELETE /api/user/avatar.
- App espera UserResource com avatar_url sempre preenchido e has_custom_avatar (bool).
- Upload response pode ser { avatar_url, has_custom_avatar, user } ou incluir user completo.
- Gravatar: https://www.gravatar.com/avatar/{md5(email)}?s=256&d=identicon
- Sem foto customizada → avatar_url = Gravatar. Com upload → avatar_url = URL do storage.

TAREFAS

1) AvatarService (app/Services/AvatarService.php)
- Métodos:
  - gravatarUrl(User $user, int $size = 256): string
  - storeUploadedAvatar(User $user, UploadedFile $file): string  // retorna path relativo
  - deleteStoredAvatar(User $user): void
  - publicUrl(?string $path): ?string  // URL absoluta via Storage disk
- Usar Storage::disk(config('filesystems.avatar_disk', 'public')) — hoje 'public', futuro 's3' via .env AVATAR_DISK=s3.
- Path sugerido: avatars/{user_id}/{uuid}.jpg (ou extensão original).
- Ao substituir avatar, apagar arquivo anterior do disco.

2) User model — accessor avatar_url
- Se avatar_path preenchido → publicUrl(avatar_path)
- Senão → gravatarUrl($this) (requer email)
- Novo accessor has_custom_avatar: return $this->avatar_path !== null;

3) syncProfileComplete()
- REMOVER exigência de avatar_path !== null (Gravatar conta como avatar válido se email existir).
- Manter demais campos (name, age, ntrp, gender, city, state, play_style).

4) ProfileController
- uploadAvatar(): delegar a AvatarService; set avatar_path; save; retornar:
  {
    "avatar_url": "...",
    "has_custom_avatar": true,
    "user": UserResource
  }
- destroyAvatar() ou DELETE /api/user/avatar:
  - Apagar avatar_path do disco e null no user
  - Retornar { message, user: UserResource } com avatar_url = Gravatar

5) Rotas (auth:sanctum)
- POST /api/user/avatar (existente)
- DELETE /api/user/avatar (novo)

6) UserResource + PlayerResource + ConversationResource
- Sempre incluir:
  - avatar_url (string — Gravatar ou custom)
  - has_custom_avatar (boolean)

7) Config
- config/filesystems.php ou config/avatar.php:
  - avatar_disk => env('AVATAR_DISK', 'public')
  - Documentar AVATAR_DISK=s3 + AWS_* para migração futura (sem implementar S3 agora se não existir).

8) TESTES (Pest)
- User sem avatar_path → avatar_url contém gravatar.com e has_custom_avatar false.
- POST upload → avatar_path set, has_custom_avatar true, URL aponta storage local.
- DELETE → avatar_path null, avatar_url volta Gravatar.
- syncProfileComplete true sem avatar_path mas com email.

9) DOCS
- Atualizar docs/API.md seção Profile / Avatar.

REFERÊNCIAS
- app/Http/Controllers/Api/ProfileController.php
- app/Http/Requests/UploadAvatarRequest.php
- app/Http/Resources/UserResource.php
- app/Models/User.php
- routes/api.php
```
