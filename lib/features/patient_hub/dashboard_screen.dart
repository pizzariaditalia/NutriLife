// Busque a linha do AppBar dentro de lib/features/patient_hub/dashboard_screen.dart e substitua o AppBar por este:
      appBar: AppBar(
        title: const Text('Meu Painel'),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          )
        ],
      ),
