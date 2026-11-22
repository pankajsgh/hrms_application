import 'package:flutter/foundation.dart';
import 'package:hrms/core/common.dart';
import '../../employees/data/employees_repository.dart';
import '../data/recruitment_repository.dart';

class RecruitmentController extends ChangeNotifier {
  final RecruitmentRepository _repository = RecruitmentRepository();

  bool isLoading = false;
  int currentTab = 0; // 0 jobs, 1 pipeline, 2 interviews
  List<Rec> jobs = [];
  List<Rec> candidates = [];
  List<Rec> interviews = [];
  List<Rec> employees = [];
  Map<String, int> stats = {};
  String jobFilter = 'All';
  int? pipeJob;
  String searchQuery = '';
  bool boardView = true;
  String interviewFilter = 'Upcoming';

  Future<void> loadRecruitment() async {
    isLoading = true;
    notifyListeners();

    jobs = await _repository.fetchJobs();
    if (pipeJob != null && !jobs.any((j) => j['id'] == pipeJob)) {
      pipeJob = null;
    }
    candidates = await _repository.fetchCandidates(jobId: pipeJob, q: searchQuery);
    interviews = await _repository.fetchInterviews();
    stats = await _repository.fetchRecruitmentStats();
    employees = await EmployeesRepository().employees(activeOnly: true);

    isLoading = false;
    notifyListeners();
  }

  void setTab(int tab) {
    currentTab = tab;
    notifyListeners();
  }

  void setJobFilter(String filter) {
    jobFilter = filter;
    notifyListeners();
  }

  void setPipeJob(int? jobId) {
    pipeJob = jobId;
    loadRecruitment();
  }

  void setSearchQuery(String q) {
    searchQuery = q.trim();
    loadRecruitment();
  }

  void setBoardView(bool board) {
    boardView = board;
    notifyListeners();
  }

  void setInterviewFilter(String filter) {
    interviewFilter = filter;
    notifyListeners();
  }

  Future<void> createJob(Rec data) async {
    await _repository.createJob(data);
    await loadRecruitment();
  }

  Future<void> updateJob(int id, Rec data, {String? currentApproval}) async {
    await _repository.updateJob(id, data, currentApproval: currentApproval);
    await loadRecruitment();
  }

  Future<void> decideJob(int id, bool approve, String reason) async {
    await _repository.decideJob(id, approve, reason);
    await loadRecruitment();
  }

  Future<void> deleteJob(int id) async {
    await _repository.deleteJob(id);
    await loadRecruitment();
  }

  Future<void> saveCandidate(Rec data, {int? id}) async {
    await _repository.saveCandidate(data, id: id);
    await loadRecruitment();
  }

  Future<void> setStage(int id, String stage) async {
    await _repository.setStage(id, stage);
    await loadRecruitment();
  }

  Future<void> deleteCandidate(int id) async {
    await _repository.deleteCandidate(id);
    await loadRecruitment();
  }

  Future<void> attachResume(int id, String source) async {
    await _repository.attachResume(id, source);
    await loadRecruitment();
  }

  Future<void> markConverted(int candidateId, int employeeId) async {
    await _repository.markConverted(candidateId, employeeId);
    await loadRecruitment();
  }

  Future<void> saveInterview(Rec data, {int? id}) async {
    await _repository.saveInterview(data, id: id);
    await loadRecruitment();
  }

  Future<void> setInterviewResult(int id, String result, String notes) async {
    await _repository.setInterviewResult(id, result, notes);
    await loadRecruitment();
  }

  Future<void> deleteInterview(int id) async {
    await _repository.deleteInterview(id);
    await loadRecruitment();
  }
}
