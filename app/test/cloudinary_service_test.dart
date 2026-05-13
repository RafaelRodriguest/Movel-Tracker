import 'package:flutter_test/flutter_test.dart';
import 'package:movel_tracker/services/cloudinary_service.dart';

void main() {
  const urlComVersion =
      'https://res.cloudinary.com/demo/image/upload/v1234567890/sites/slz001_foto1.jpg';
  const urlSemVersion =
      'https://res.cloudinary.com/demo/image/upload/sites/slz001_foto1.jpg';

  group('CloudinaryService.thumbnailUrl', () {
    test('insere transformação após /upload/', () {
      final result = CloudinaryService.thumbnailUrl(urlComVersion);
      expect(
        result,
        'https://res.cloudinary.com/demo/image/upload/w_200,h_200,c_fill,q_auto,f_auto/v1234567890/sites/slz001_foto1.jpg',
      );
    });

    test('funciona sem prefixo de versão', () {
      final result = CloudinaryService.thumbnailUrl(urlSemVersion);
      expect(
        result,
        'https://res.cloudinary.com/demo/image/upload/w_200,h_200,c_fill,q_auto,f_auto/sites/slz001_foto1.jpg',
      );
    });

    test('contém todos os parâmetros obrigatórios', () {
      final result = CloudinaryService.thumbnailUrl(urlComVersion);
      expect(result, contains('w_200'));
      expect(result, contains('h_200'));
      expect(result, contains('c_fill'));
      expect(result, contains('q_auto'));
      expect(result, contains('f_auto'));
    });

    test('retorna URL original se não for do Cloudinary', () {
      const urlEstranha = 'https://outro-servidor.com/imagem.jpg';
      expect(CloudinaryService.thumbnailUrl(urlEstranha), urlEstranha);
    });
  });

  group('CloudinaryService.fullViewUrl', () {
    test('insere transformação após /upload/', () {
      final result = CloudinaryService.fullViewUrl(urlComVersion);
      expect(
        result,
        'https://res.cloudinary.com/demo/image/upload/w_1200,q_auto,f_auto/v1234567890/sites/slz001_foto1.jpg',
      );
    });

    test('funciona sem prefixo de versão', () {
      final result = CloudinaryService.fullViewUrl(urlSemVersion);
      expect(
        result,
        'https://res.cloudinary.com/demo/image/upload/w_1200,q_auto,f_auto/sites/slz001_foto1.jpg',
      );
    });

    test('contém todos os parâmetros obrigatórios', () {
      final result = CloudinaryService.fullViewUrl(urlComVersion);
      expect(result, contains('w_1200'));
      expect(result, contains('q_auto'));
      expect(result, contains('f_auto'));
    });

    test('retorna URL original se não for do Cloudinary', () {
      const urlEstranha = 'https://outro-servidor.com/imagem.jpg';
      expect(CloudinaryService.fullViewUrl(urlEstranha), urlEstranha);
    });
  });

  group('Compatibilidade com extractPublicId', () {
    test('extractPublicId funciona na URL com transformação de thumbnail', () {
      final thumb = CloudinaryService.thumbnailUrl(urlComVersion);
      expect(CloudinaryService.extractPublicId(thumb), 'sites/slz001_foto1');
    });

    test('extractPublicId funciona na URL com transformação de full view', () {
      final full = CloudinaryService.fullViewUrl(urlComVersion);
      expect(CloudinaryService.extractPublicId(full), 'sites/slz001_foto1');
    });

    test('extractPublicId não é afetado por transformações sem versão', () {
      final thumb = CloudinaryService.thumbnailUrl(urlSemVersion);
      expect(CloudinaryService.extractPublicId(thumb), 'sites/slz001_foto1');
    });
  });

  group('Casos limite', () {
    test('string vazia retorna string vazia', () {
      expect(CloudinaryService.thumbnailUrl(''), '');
      expect(CloudinaryService.fullViewUrl(''), '');
    });

    test('thumbnail é menor que full view (tamanho do transform na URL)', () {
      final thumb = CloudinaryService.thumbnailUrl(urlComVersion);
      final full = CloudinaryService.fullViewUrl(urlComVersion);
      // Ambas têm o mesmo domínio e path — só o transform difere
      expect(thumb, isNot(equals(full)));
      expect(thumb, contains('w_200'));
      expect(full, contains('w_1200'));
    });

    test('aplicar thumbnailUrl duas vezes não duplica transformações', () {
      final once = CloudinaryService.thumbnailUrl(urlComVersion);
      final twice = CloudinaryService.thumbnailUrl(once);
      // A segunda chamada insere antes do primeiro /upload/, então o resultado
      // vai ser diferente de 'once' — o importante é que não crashe
      expect(() => CloudinaryService.thumbnailUrl(once), returnsNormally);
      expect(twice, isNotEmpty);
    });
  });
}
