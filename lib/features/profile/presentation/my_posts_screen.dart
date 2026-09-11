import 'package:flutter/material.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final List<Map<String, dynamic>> myPosts = [
    {
      'id': '1',
      'imageUrl': 'https://picsum.photos/400/400?random=10',
      'caption': 'Treino de hoje concluído com sucesso! 🏋️‍♂️',
      'likes': '124',
      'comments': [
        {'user': 'Carlos', 'text': 'Brabo demais! 💪🏼🏽'},
        {'user': 'Mariana', 'text': 'Boa! Pra cima! 🔥'},
      ],
    },
    {
      'id': '2',
      'imageUrl': 'https://picsum.photos/400/400?random=11',
      'caption': 'Batendo o recorde pessoal no supino 💪',
      'likes': '98',
      'comments': [
        {'user': 'Felipe', 'text': 'Quanto de carga?'},
      ],
    },
    {
      'id': '3',
      'imageUrl': 'https://picsum.photos/400/400?random=12',
      'caption': 'Foco total na dieta e consistência.',
      'likes': '210',
      'comments': <Map<String, String>>[],
    },
  ];

  // Modal para Editar a Legenda
  void _openEditDialog(BuildContext context, int index) {
    final captionController = TextEditingController(
      text: myPosts[index]['caption'],
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Editar Legenda',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: captionController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Escreva sua nova legenda...',
                  hintStyle: TextStyle(color: Color(0xFF666666)),
                  filled: true,
                  fillColor: Color(0xFF1F1F1F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF1E40),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    myPosts[index]['caption'] = captionController.text.trim();
                  });
                  Navigator.pop(context); // Fecha edição
                  Navigator.pop(context); // Fecha detalhe
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Legenda atualizada!')),
                  );
                },
                child: const Text(
                  'SALVAR ALTERAÇÕES',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Modal para Ver os Comentários
  void _openCommentsModal(BuildContext context, List<dynamic> comments) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Comentários (${comments.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (comments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Nenhum comentário nesta publicação.',
                      style: TextStyle(color: Color(0xFF888888)),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: comments.length,
                    separatorBuilder: (_, _) =>
                        const Divider(color: Color(0xFF262626), height: 16),
                    itemBuilder: (context, idx) {
                      final c = comments[idx];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(0xFFFF1E40),
                            child: Text(
                              c['user']![0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${c['user']} ',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  TextSpan(
                                    text: c['text'],
                                    style: const TextStyle(
                                      color: Color(0xFFCCCCCC),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Confirmação para Excluir Post
  void _confirmDeletePost(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: const Text(
          'Excluir Publicação',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Tem certeza que deseja apagar esta publicação permanentemente?',
          style: TextStyle(color: Color(0xFF888888)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCELAR',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                myPosts.removeAt(index);
              });
              Navigator.pop(context); // Dialog
              Navigator.pop(context); // Detalhes
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Publicação excluída.')),
              );
            },
            child: const Text(
              'EXCLUIR',
              style: TextStyle(color: Color(0xFFFF1E40)),
            ),
          ),
        ],
      ),
    );
  }

  // Detalhes do Post (Ao clicar no Grid)
  void _openPostDetail(
    BuildContext context,
    Map<String, dynamic> post,
    int index,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final comments = post['comments'] as List<dynamic>;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra do Topo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Detalhes do Post',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () => _openEditDialog(context, index),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFFF1E40),
                        ),
                        onPressed: () => _confirmDeletePost(context, index),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Imagem do Post
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(post['imageUrl']!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 12),

              // Curtidas e Acesso aos Comentários
              Row(
                children: [
                  const Icon(
                    Icons.favorite,
                    color: Color(0xFFFF1E40),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${post['likes']} curtidas',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Color(0xFF888888),
                      size: 16,
                    ),
                    label: Text(
                      'Comentários (${comments.length})',
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 13,
                      ),
                    ),
                    onPressed: () => _openCommentsModal(context, comments),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Legenda
              Text(
                post['caption']!,
                style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        elevation: 0,
        title: const Text(
          'MEUS POSTS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: myPosts.isEmpty
          ? const Center(
              child: Text(
                'Você ainda não fez nenhuma publicação.',
                style: TextStyle(color: Color(0xFF888888)),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: myPosts.length,
              itemBuilder: (context, index) {
                final post = myPosts[index];
                return GestureDetector(
                  onTap: () => _openPostDetail(context, post, index),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(post['imageUrl']!, fit: BoxFit.cover),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 10,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                post['likes']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
