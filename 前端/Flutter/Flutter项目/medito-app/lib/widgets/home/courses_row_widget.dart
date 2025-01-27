import 'package:Medito/network/api_response.dart';
import 'package:Medito/network/home/courses_bloc.dart';
import 'package:Medito/network/home/courses_response.dart';
import 'package:Medito/utils/colors.dart';
import 'package:Medito/utils/navigation.dart';
import 'package:Medito/utils/utils.dart';
import 'package:flutter/material.dart';

class CoursesRowWidget extends StatefulWidget {
  @override
  CoursesRowWidgetState createState() => CoursesRowWidgetState();

  CoursesRowWidget({Key key}) : super(key: key);
}

class CoursesRowWidgetState extends State<CoursesRowWidget> {
  final _bloc = CoursesBloc();

  void refresh() {
    _bloc.fetchCourses(skipCache: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 32.0, left: 16),
          child: Text('Courses', style: Theme.of(context).textTheme.headline3),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 0, left: 16, bottom: 8.0),
          child: Text('LISTEN IN ORDER',
              style: Theme.of(context).textTheme.caption),
        ),
        Container(
          height: 208,
          child: StreamBuilder<ApiResponse<CoursesResponse>>(
              stream: _bloc.coursesList.stream,
              initialData: ApiResponse.loading(),
              builder: (context, snapshot) {
                switch (snapshot.data.status) {
                  case Status.LOADING:
                    return _getLoadingWidget();
                    break;
                  case Status.COMPLETED:
                    return ListView.builder(
                        padding: const EdgeInsets.only(left: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: snapshot.data.body.data.length,
                        itemBuilder: (context, index) {
                          return CoursesRowItemWidget(
                              snapshot.data.body.data[index]);
                        });
                    break;
                  case Status.ERROR:
                    return Icon(Icons.error);
                    break;
                }
                return Container();
              }),
        ),
      ],
    );
  }

  Widget _getLoadingWidget() => Row(
    children: [
      Container(width: 16),
      Container(color: MeditoColors.moonlight, height: 132, width: 132),
      Container(width: 16),
      Container(color: MeditoColors.moonlight, height: 132, width: 132),
    ],
  );
}

class CoursesRowItemWidget extends StatelessWidget {
  const CoursesRowItemWidget(
    this.data, {
    Key key,
  }) : super(key: key);

  final Data data;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => NavigationFactory.navigateToScreenFromString(
          data.type, data.id, context),
      child: Container(
        width: 148,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                    width: 132, height: 132, child: _buildCardBackground()),
                Positioned.fill(
                  child: Center(
                    child: SizedBox(
                        width: 92,
                        height: 92,
                        child: getNetworkImageWidget(data.coverUrl)),
                  ),
                ),
              ],
            ),
            Container(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                data.title,
                style: Theme.of(context).textTheme.headline4,
              ),
            ),
            Container(height: 2),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(data.subtitle,
                  style: Theme.of(context).textTheme.subtitle1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBackground() => data.backgroundImage.isEmptyOrNull()
      ? Container(
          color: data.colorPrimary.isEmptyOrNull()
              ? MeditoColors.moonlight
              : parseColor(data.colorPrimary))
      : getNetworkImageWidget(data.backgroundImageUrl);
}
