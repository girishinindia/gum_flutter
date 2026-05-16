// Per-row sub-resources of the user's profile. Each maps 1:1 to a
// gum_api `/user-<thing>/me` endpoint and mirrors the web client's
// TypeScript interfaces in `gum_web/lib/users/client.ts`.
//
// Kept in a single file because they're all flat, read-mostly DTOs
// with no behaviour. The forms that consume them live one layer up
// in presentation/.

import 'package:equatable/equatable.dart';

import 'master_models.dart';

// ── /user-education ──────────────────────────────────────────────────

class UserEducation extends Equatable {
  const UserEducation({
    this.id,
    this.userId,
    required this.educationLevelId,
    required this.institutionName,
    this.boardOrUniversity,
    this.fieldOfStudy,
    this.specialization,
    this.gradeOrPercentage,
    this.gradeType,
    this.startDate,
    this.endDate,
    this.isCurrentlyStudying,
    this.isHighestQualification,
    this.description,
    this.certificateUrl,
    this.educationLevel,
  });

  final int?     id;
  final int?     userId;
  final int      educationLevelId;
  final String   institutionName;
  final String?  boardOrUniversity;
  final String?  fieldOfStudy;
  final String?  specialization;
  final String?  gradeOrPercentage;
  /// 'percentage' | 'cgpa' | 'gpa' | 'grade' | 'pass_fail' | 'other'
  final String?  gradeType;
  final String?  startDate;        // YYYY-MM-DD
  final String?  endDate;
  final bool?    isCurrentlyStudying;
  final bool?    isHighestQualification;
  final String?  description;
  final String?  certificateUrl;
  final EducationLevel? educationLevel;

  factory UserEducation.fromJson(Map<String, dynamic> j) => UserEducation(
        id:                     (j['id'] as num?)?.toInt(),
        userId:                 (j['user_id'] as num?)?.toInt(),
        educationLevelId:       (j['education_level_id'] as num?)?.toInt() ?? 0,
        institutionName:        (j['institution_name'] ?? '') as String,
        boardOrUniversity:      j['board_or_university'] as String?,
        fieldOfStudy:           j['field_of_study'] as String?,
        specialization:         j['specialization'] as String?,
        gradeOrPercentage:      j['grade_or_percentage'] as String?,
        gradeType:              j['grade_type'] as String?,
        startDate:              j['start_date'] as String?,
        endDate:                j['end_date'] as String?,
        isCurrentlyStudying:    j['is_currently_studying'] as bool?,
        isHighestQualification: j['is_highest_qualification'] as bool?,
        description:            j['description'] as String?,
        certificateUrl:         j['certificate_url'] as String?,
        educationLevel: j['education_level'] is Map<String, dynamic>
            ? EducationLevel.fromJson(j['education_level'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'education_level_id':       educationLevelId,
        'institution_name':         institutionName,
        if (boardOrUniversity != null)      'board_or_university':      boardOrUniversity,
        if (fieldOfStudy != null)           'field_of_study':           fieldOfStudy,
        if (specialization != null)         'specialization':           specialization,
        if (gradeOrPercentage != null)      'grade_or_percentage':      gradeOrPercentage,
        if (gradeType != null)              'grade_type':               gradeType,
        if (startDate != null)              'start_date':               startDate,
        if (endDate != null)                'end_date':                 endDate,
        if (isCurrentlyStudying != null)    'is_currently_studying':    isCurrentlyStudying,
        if (isHighestQualification != null) 'is_highest_qualification': isHighestQualification,
        if (description != null)            'description':              description,
        if (certificateUrl != null)         'certificate_url':          certificateUrl,
      };

  @override
  List<Object?> get props => [
        id, userId, educationLevelId, institutionName, boardOrUniversity,
        fieldOfStudy, specialization, gradeOrPercentage, gradeType,
        startDate, endDate, isCurrentlyStudying, isHighestQualification,
        description, certificateUrl, educationLevel,
      ];
}

// ── /user-experience ─────────────────────────────────────────────────

class UserExperience extends Equatable {
  const UserExperience({
    this.id,
    this.userId,
    required this.companyName,
    required this.jobTitle,
    this.designationId,
    this.employmentType,
    this.department,
    this.location,
    this.workMode,
    required this.startDate,
    this.endDate,
    this.isCurrentJob,
    this.description,
    this.keyAchievements,
    this.skillsUsed,
    this.salaryRange,
    this.referenceName,
    this.referencePhone,
    this.referenceEmail,
    this.designation,
  });

  final int?    id;
  final int?    userId;
  final String  companyName;
  final String  jobTitle;
  final int?    designationId;
  /// 'full_time'|'part_time'|'contract'|'internship'|'freelance'|
  /// 'self_employed'|'volunteer'|'apprenticeship'|'other'
  final String? employmentType;
  final String? department;
  final String? location;
  /// 'on_site'|'remote'|'hybrid'
  final String? workMode;
  final String  startDate;       // YYYY-MM-DD (required)
  final String? endDate;
  final bool?   isCurrentJob;
  final String? description;
  final String? keyAchievements;
  final String? skillsUsed;
  final String? salaryRange;
  final String? referenceName;
  final String? referencePhone;
  final String? referenceEmail;
  final Designation? designation;

  factory UserExperience.fromJson(Map<String, dynamic> j) => UserExperience(
        id:             (j['id'] as num?)?.toInt(),
        userId:         (j['user_id'] as num?)?.toInt(),
        companyName:    (j['company_name'] ?? '') as String,
        jobTitle:       (j['job_title']    ?? '') as String,
        designationId:  (j['designation_id'] as num?)?.toInt(),
        employmentType: j['employment_type'] as String?,
        department:     j['department']      as String?,
        location:       j['location']        as String?,
        workMode:       j['work_mode']       as String?,
        startDate:      (j['start_date']     ?? '') as String,
        endDate:        j['end_date']        as String?,
        isCurrentJob:   j['is_current_job']  as bool?,
        description:    j['description']     as String?,
        keyAchievements:j['key_achievements']as String?,
        skillsUsed:     j['skills_used']     as String?,
        salaryRange:    j['salary_range']    as String?,
        referenceName:  j['reference_name']  as String?,
        referencePhone: j['reference_phone'] as String?,
        referenceEmail: j['reference_email'] as String?,
        designation: j['designation'] is Map<String, dynamic>
            ? Designation.fromJson(j['designation'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'company_name':   companyName,
        'job_title':      jobTitle,
        if (designationId  != null) 'designation_id':   designationId,
        if (employmentType != null) 'employment_type':  employmentType,
        if (department     != null) 'department':       department,
        if (location       != null) 'location':         location,
        if (workMode       != null) 'work_mode':        workMode,
        'start_date':     startDate,
        if (endDate        != null) 'end_date':         endDate,
        if (isCurrentJob   != null) 'is_current_job':   isCurrentJob,
        if (description    != null) 'description':      description,
        if (keyAchievements!= null) 'key_achievements': keyAchievements,
        if (skillsUsed     != null) 'skills_used':      skillsUsed,
        if (salaryRange    != null) 'salary_range':     salaryRange,
        if (referenceName  != null) 'reference_name':   referenceName,
        if (referencePhone != null) 'reference_phone':  referencePhone,
        if (referenceEmail != null) 'reference_email':  referenceEmail,
      };

  @override
  List<Object?> get props => [
        id, userId, companyName, jobTitle, designationId, employmentType,
        department, location, workMode, startDate, endDate, isCurrentJob,
        description, keyAchievements, skillsUsed, salaryRange,
        referenceName, referencePhone, referenceEmail, designation,
      ];
}

// ── /user-projects ───────────────────────────────────────────────────

class UserProject extends Equatable {
  const UserProject({
    this.id,
    this.userId,
    required this.projectTitle,
    this.description,
    this.roleInProject,
    this.organizationName,
    this.technologiesUsed,
    this.startDate,
    this.endDate,
    this.isOngoing,
    this.projectStatus,
    this.projectUrl,
    this.repositoryUrl,
    this.demoUrl,
    this.isFeatured,
  });

  final int?    id;
  final int?    userId;
  final String  projectTitle;
  final String? description;
  final String? roleInProject;
  final String? organizationName;
  final String? technologiesUsed;
  final String? startDate;
  final String? endDate;
  final bool?   isOngoing;
  /// 'planning'|'in_progress'|'completed'|'on_hold'|'cancelled'|'abandoned'
  final String? projectStatus;
  final String? projectUrl;
  final String? repositoryUrl;
  final String? demoUrl;
  final bool?   isFeatured;

  factory UserProject.fromJson(Map<String, dynamic> j) => UserProject(
        id:              (j['id'] as num?)?.toInt(),
        userId:          (j['user_id'] as num?)?.toInt(),
        projectTitle:    (j['project_title'] ?? '') as String,
        description:     j['description'] as String?,
        roleInProject:   j['role_in_project'] as String?,
        organizationName:j['organization_name'] as String?,
        technologiesUsed:j['technologies_used'] as String?,
        startDate:       j['start_date'] as String?,
        endDate:         j['end_date'] as String?,
        isOngoing:       j['is_ongoing'] as bool?,
        projectStatus:   j['project_status'] as String?,
        projectUrl:      j['project_url'] as String?,
        repositoryUrl:   j['repository_url'] as String?,
        demoUrl:         j['demo_url'] as String?,
        isFeatured:      j['is_featured'] as bool?,
      );

  Map<String, dynamic> toJson() => {
        'project_title': projectTitle,
        if (description       != null) 'description':        description,
        if (roleInProject     != null) 'role_in_project':    roleInProject,
        if (organizationName  != null) 'organization_name':  organizationName,
        if (technologiesUsed  != null) 'technologies_used':  technologiesUsed,
        if (startDate         != null) 'start_date':         startDate,
        if (endDate           != null) 'end_date':           endDate,
        if (isOngoing         != null) 'is_ongoing':         isOngoing,
        if (projectStatus     != null) 'project_status':     projectStatus,
        if (projectUrl        != null) 'project_url':        projectUrl,
        if (repositoryUrl     != null) 'repository_url':     repositoryUrl,
        if (demoUrl           != null) 'demo_url':           demoUrl,
        if (isFeatured        != null) 'is_featured':        isFeatured,
      };

  @override
  List<Object?> get props => [
        id, userId, projectTitle, description, roleInProject, organizationName,
        technologiesUsed, startDate, endDate, isOngoing, projectStatus,
        projectUrl, repositoryUrl, demoUrl, isFeatured,
      ];
}

// ── /user-skills ─────────────────────────────────────────────────────

class UserSkill extends Equatable {
  const UserSkill({
    this.id,
    this.userId,
    required this.skillId,
    this.proficiencyLevel,
    this.yearsOfExperience,
    this.isPrimary,
    this.certificateUrl,
    this.endorsementCount,
    this.skill,
  });

  final int?    id;
  final int?    userId;
  final int     skillId;
  /// 'beginner' | 'elementary' | 'intermediate' | 'advanced' | 'expert'
  final String? proficiencyLevel;
  final num?    yearsOfExperience;
  final bool?   isPrimary;
  final String? certificateUrl;
  final int?    endorsementCount;
  final MasterSkill? skill;

  factory UserSkill.fromJson(Map<String, dynamic> j) => UserSkill(
        id:               (j['id'] as num?)?.toInt(),
        userId:           (j['user_id'] as num?)?.toInt(),
        skillId:          (j['skill_id'] as num?)?.toInt() ?? 0,
        proficiencyLevel: j['proficiency_level'] as String?,
        yearsOfExperience: (j['years_of_experience'] as num?),
        isPrimary:        j['is_primary'] as bool?,
        certificateUrl:   j['certificate_url'] as String?,
        endorsementCount: (j['endorsement_count'] as num?)?.toInt(),
        skill: j['skill'] is Map<String, dynamic>
            ? MasterSkill.fromJson(j['skill'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'skill_id': skillId,
        if (proficiencyLevel  != null) 'proficiency_level':   proficiencyLevel,
        if (yearsOfExperience != null) 'years_of_experience': yearsOfExperience,
        if (isPrimary         != null) 'is_primary':          isPrimary,
        if (certificateUrl    != null) 'certificate_url':     certificateUrl,
      };

  @override
  List<Object?> get props => [
        id, userId, skillId, proficiencyLevel, yearsOfExperience,
        isPrimary, certificateUrl, endorsementCount, skill,
      ];
}

// ── /user-languages ──────────────────────────────────────────────────

class UserLanguage extends Equatable {
  const UserLanguage({
    this.id,
    this.userId,
    required this.languageId,
    this.proficiencyLevel,
    this.canRead,
    this.canWrite,
    this.canSpeak,
    this.isPrimary,
    this.isNative,
    this.language,
  });

  final int?    id;
  final int?    userId;
  final int     languageId;
  /// 'basic' | 'conversational' | 'professional' | 'fluent' | 'native'
  final String? proficiencyLevel;
  final bool?   canRead;
  final bool?   canWrite;
  final bool?   canSpeak;
  final bool?   isPrimary;
  final bool?   isNative;
  final MasterLanguage? language;

  factory UserLanguage.fromJson(Map<String, dynamic> j) => UserLanguage(
        id:               (j['id'] as num?)?.toInt(),
        userId:           (j['user_id'] as num?)?.toInt(),
        languageId:       (j['language_id'] as num?)?.toInt() ?? 0,
        proficiencyLevel: j['proficiency_level'] as String?,
        canRead:          j['can_read']  as bool?,
        canWrite:         j['can_write'] as bool?,
        canSpeak:         j['can_speak'] as bool?,
        isPrimary:        j['is_primary'] as bool?,
        isNative:         j['is_native']  as bool?,
        language: j['language'] is Map<String, dynamic>
            ? MasterLanguage.fromJson(j['language'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'language_id': languageId,
        if (proficiencyLevel != null) 'proficiency_level': proficiencyLevel,
        if (canRead   != null) 'can_read':  canRead,
        if (canWrite  != null) 'can_write': canWrite,
        if (canSpeak  != null) 'can_speak': canSpeak,
        if (isPrimary != null) 'is_primary': isPrimary,
        if (isNative  != null) 'is_native':  isNative,
      };

  @override
  List<Object?> get props => [
        id, userId, languageId, proficiencyLevel, canRead, canWrite, canSpeak,
        isPrimary, isNative, language,
      ];
}

// ── /user-social-medias ──────────────────────────────────────────────

class UserSocialMedia extends Equatable {
  const UserSocialMedia({
    this.id,
    this.userId,
    required this.platform,
    required this.url,
    this.username,
    this.isPublic,
    this.displayOrder,
  });

  final int?    id;
  final int?    userId;
  final String  platform;  // canonical code: 'linkedin', 'github', ...
  final String  url;
  final String? username;
  final bool?   isPublic;
  final int?    displayOrder;

  factory UserSocialMedia.fromJson(Map<String, dynamic> j) => UserSocialMedia(
        id:           (j['id'] as num?)?.toInt(),
        userId:       (j['user_id'] as num?)?.toInt(),
        platform:     (j['platform'] ?? '') as String,
        url:          (j['url']      ?? '') as String,
        username:     j['username']      as String?,
        isPublic:     j['is_public']     as bool?,
        displayOrder: (j['display_order'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        'platform': platform,
        'url':      url,
        if (username     != null) 'username':      username,
        if (isPublic     != null) 'is_public':     isPublic,
        if (displayOrder != null) 'display_order': displayOrder,
      };

  @override
  List<Object?> get props => [id, userId, platform, url, username, isPublic, displayOrder];
}

// ── /user-documents ──────────────────────────────────────────────────

class UserDocument extends Equatable {
  const UserDocument({
    this.id,
    this.userId,
    required this.documentTypeId,
    this.documentId,
    this.documentNumber,
    this.file,
    this.issueDate,
    this.expiryDate,
    this.verificationStatus,
    this.rejectionReason,
    this.adminNotes,
    this.verifiedAt,
    this.documentType,
    this.document,
  });

  final int?    id;
  final int?    userId;
  final int     documentTypeId;
  final int?    documentId;
  final String? documentNumber;
  final String? file;          // URL after server upload
  final String? issueDate;     // YYYY-MM-DD
  final String? expiryDate;
  /// 'pending'|'under_review'|'verified'|'rejected'|'expired'|'reupload'
  final String? verificationStatus;
  final String? rejectionReason;
  final String? adminNotes;
  final String? verifiedAt;
  final DocumentType?   documentType;
  final MasterDocument? document;

  factory UserDocument.fromJson(Map<String, dynamic> j) => UserDocument(
        id:                 (j['id'] as num?)?.toInt(),
        userId:             (j['user_id'] as num?)?.toInt(),
        documentTypeId:     (j['document_type_id'] as num?)?.toInt() ?? 0,
        documentId:         (j['document_id'] as num?)?.toInt(),
        documentNumber:     j['document_number'] as String?,
        file:               j['file'] as String?,
        issueDate:          j['issue_date'] as String?,
        expiryDate:         j['expiry_date'] as String?,
        verificationStatus: j['verification_status'] as String?,
        rejectionReason:    j['rejection_reason'] as String?,
        adminNotes:         j['admin_notes'] as String?,
        verifiedAt:         j['verified_at'] as String?,
        documentType: j['document_type'] is Map<String, dynamic>
            ? DocumentType.fromJson(j['document_type'] as Map<String, dynamic>)
            : null,
        document: j['document'] is Map<String, dynamic>
            ? MasterDocument.fromJson({
                'id':                (j['document'] as Map)['id'],
                'name':              (j['document'] as Map)['name'],
                'document_type_id':  (j['document'] as Map)['document_type_id']
                                        ?? (j['document_type_id'] ?? 0),
              })
            : null,
      );

  Map<String, dynamic> toJson() => {
        'document_type_id': documentTypeId,
        if (documentId     != null) 'document_id':     documentId,
        if (documentNumber != null) 'document_number': documentNumber,
        if (issueDate      != null) 'issue_date':      issueDate,
        if (expiryDate     != null) 'expiry_date':     expiryDate,
      };

  @override
  List<Object?> get props => [
        id, userId, documentTypeId, documentId, documentNumber, file,
        issueDate, expiryDate, verificationStatus, rejectionReason,
        adminNotes, verifiedAt, documentType, document,
      ];
}

// ── /user-badges (read-only) ─────────────────────────────────────────

class UserBadge extends Equatable {
  const UserBadge({
    required this.id,
    required this.badgeName,
    this.description,
    this.iconUrl,
    required this.awardedAt,
  });

  final int     id;
  final String  badgeName;
  final String? description;
  final String? iconUrl;
  final String  awardedAt;

  factory UserBadge.fromJson(Map<String, dynamic> j) => UserBadge(
        id:          (j['id'] as num).toInt(),
        badgeName:   (j['badge_name'] ?? '') as String,
        description: j['description'] as String?,
        iconUrl:     j['icon_url'] as String?,
        awardedAt:   (j['awarded_at'] ?? '') as String,
      );

  @override
  List<Object?> get props => [id, badgeName, description, iconUrl, awardedAt];
}

// ── /instructor-profiles/me ──────────────────────────────────────────

class InstructorProfile extends Equatable {
  const InstructorProfile({
    this.id,
    this.userId,
    this.expertise,
    this.teachingLanguages,
    this.yearsTeaching,
    this.totalStudents,
    this.totalCourses,
    this.averageRating,
    this.isVerified,
    this.isFeatured,
    this.paypalEmail,
    this.stripeAccountId,
  });

  final int?    id;
  final int?    userId;
  final String? expertise;
  final String? teachingLanguages;
  final num?    yearsTeaching;
  final int?    totalStudents;
  final int?    totalCourses;
  final num?    averageRating;
  final bool?   isVerified;
  final bool?   isFeatured;
  final String? paypalEmail;
  final String? stripeAccountId;

  factory InstructorProfile.fromJson(Map<String, dynamic> j) => InstructorProfile(
        id:               (j['id'] as num?)?.toInt(),
        userId:           (j['user_id'] as num?)?.toInt(),
        expertise:        j['expertise'] as String?,
        teachingLanguages:j['teaching_languages'] as String?,
        yearsTeaching:    j['years_teaching'] as num?,
        totalStudents:    (j['total_students'] as num?)?.toInt(),
        totalCourses:     (j['total_courses']  as num?)?.toInt(),
        averageRating:    j['average_rating']  as num?,
        isVerified:       j['is_verified']     as bool?,
        isFeatured:       j['is_featured']     as bool?,
        paypalEmail:      j['paypal_email']    as String?,
        stripeAccountId:  j['stripe_account_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (expertise         != null) 'expertise':         expertise,
        if (teachingLanguages != null) 'teaching_languages':teachingLanguages,
        if (yearsTeaching     != null) 'years_teaching':    yearsTeaching,
        if (paypalEmail       != null) 'paypal_email':      paypalEmail,
        if (stripeAccountId   != null) 'stripe_account_id': stripeAccountId,
      };

  @override
  List<Object?> get props => [
        id, userId, expertise, teachingLanguages, yearsTeaching,
        totalStudents, totalCourses, averageRating,
        isVerified, isFeatured, paypalEmail, stripeAccountId,
      ];
}
