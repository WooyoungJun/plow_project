import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'components/CustomAppbar.dart';
import 'components/CustomDrawer.dart';
import 'components/UserProvider.dart';

class MyInfoView extends StatefulWidget {
  @override
  State<MyInfoView> createState() => _MyInfoViewState();
}

class _MyInfoViewState extends State<MyInfoView> {
  bool isEditing = false;
  final TextEditingController nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final UserProvider userProvider =
        Provider.of<UserProvider>(context, listen: false);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Info',
        userProvider: userProvider,
        // 수정중 true이면 null
        actions: isEditing == true ? null : [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              setState(() {
                isEditing = true;
                nameController.text = userProvider.userName ?? '';
              });
            },
          ),
        ],
      ),
      endDrawer: CustomDrawer(userProvider: userProvider),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                child: Icon(Icons.account_circle, size: 120),
              ),
            ),
            Divider(
              color: Colors.grey,
              thickness: 2,
              indent: 20,
              endIndent: 20,
            ),
            Text(
              'User Name:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextFormField(
              controller: nameController,
              enabled: isEditing, // 수정 모드에서만 활성화
              decoration: InputDecoration(
                hintText: userProvider.userName!.isNotEmpty
                    ? userProvider.userName
                    : 'Enter your username',
              ),
            ),
            SizedBox(height: 16),
            Text(
              'User Email:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              userProvider.userEmail ?? 'Not available',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
      floatingActionButton: isEditing
          ? FloatingActionButton(
              onPressed: () async {
                await userProvider.setName(nameController.text);
                setState(() => isEditing = false);
              },
              child: Icon(Icons.save),
            )
          : null,
    );
  }
}
