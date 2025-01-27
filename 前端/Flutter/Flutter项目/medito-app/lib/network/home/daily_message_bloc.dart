/*This file is part of Medito App.

Medito App is free software: you can redistribute it and/or modify
it under the terms of the Affero GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Medito App is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
Affero GNU General Public License for more details.

You should have received a copy of the Affero GNU General Public License
along with Medito App. If not, see <https://www.gnu.org/licenses/>.*/

import 'dart:async';

import 'package:Medito/network/api_response.dart';
import 'package:Medito/network/home/daily_message_repo.dart';
import 'package:Medito/network/home/daily_message_response.dart';

class DailyMessageBloc {
  DailyMessageRepo _repo;
  StreamController<ApiResponse<DailyMessageResponse>> coursesList;

  DailyMessageBloc() {
    _repo = DailyMessageRepo();

    coursesList = StreamController.broadcast()..sink.add(ApiResponse.loading());

    fetchMessage();
  }

  Future<void> fetchMessage({bool skipCache = false}) async {
    try {
      var data = await _repo.getMessage(skipCache);
      coursesList.sink.add(ApiResponse.completed(data));
    } catch (e) {
      coursesList.sink.add(ApiResponse.error('An error occurred!'));
    }
  }
}
