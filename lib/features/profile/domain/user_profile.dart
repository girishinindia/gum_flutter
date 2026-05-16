// Extended user profile — the `user_profiles` row (NOT `users`).
//
// 1:1 mirror of `UserProfile` in `gum_web/lib/users/client.ts`. Field
// names match the live `user_profiles` columns verbatim (phase28 audit
// caught earlier mismatches like `aadhaar_number` vs `aadhar_number`,
// `bank_ifsc` vs `bank_ifsc_code`, etc.).
//
// Address city/state/country are FK IDs (BIGINT) on the server. The
// AddressFields cascade resolves these IDs back to display names via
// the masters API.

import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    this.id,
    this.userId,
    this.displayName,
    this.headline,
    this.bio,
    this.slug,
    this.isPublic,
    this.dateOfBirth,
    this.gender,
    // Current address
    this.currentAddressLine1,
    this.currentAddressLine2,
    this.currentCityId,
    this.currentStateId,
    this.currentCountryId,
    this.currentPostalCode,
    // Permanent address
    this.permanentAddressLine1,
    this.permanentAddressLine2,
    this.permanentCityId,
    this.permanentStateId,
    this.permanentCountryId,
    this.permanentPostalCode,
    // Emergency contact
    this.emergencyContactName,
    this.emergencyContactMobile,
    this.emergencyContactRelation,
    // KYC + bank
    this.aadharNumber,
    this.panNumber,
    this.passportNumber,
    this.bankAccountName,
    this.bankName,
    this.bankAccountNumber,
    this.bankIfscCode,
    this.upiId,
    // Media
    this.profileImageUrl,
    this.coverImageUrl,
  });

  final int?     id;
  final int?     userId;
  final String?  displayName;
  final String?  headline;
  final String?  bio;
  final String?  slug;
  final bool?    isPublic;
  final String?  dateOfBirth;   // YYYY-MM-DD
  final String?  gender;

  // Current address
  final String?  currentAddressLine1;
  final String?  currentAddressLine2;
  final int?     currentCityId;
  final int?     currentStateId;
  final int?     currentCountryId;
  final String?  currentPostalCode;

  // Permanent address
  final String?  permanentAddressLine1;
  final String?  permanentAddressLine2;
  final int?     permanentCityId;
  final int?     permanentStateId;
  final int?     permanentCountryId;
  final String?  permanentPostalCode;

  // Emergency
  final String?  emergencyContactName;
  final String?  emergencyContactMobile;
  final String?  emergencyContactRelation;

  // KYC + bank
  final String?  aadharNumber;
  final String?  panNumber;
  final String?  passportNumber;
  final String?  bankAccountName;
  final String?  bankName;
  final String?  bankAccountNumber;
  final String?  bankIfscCode;
  final String?  upiId;

  // Media
  final String?  profileImageUrl;
  final String?  coverImageUrl;

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        id:     (j['id']      as num?)?.toInt(),
        userId: (j['user_id'] as num?)?.toInt(),
        displayName: j['display_name'] as String?,
        headline:    j['headline']     as String?,
        bio:         j['bio']          as String?,
        slug:        j['slug']         as String?,
        isPublic:    j['is_public']    as bool?,
        dateOfBirth: j['date_of_birth'] as String?,
        gender:      j['gender']       as String?,
        currentAddressLine1: j['current_address_line1'] as String?,
        currentAddressLine2: j['current_address_line2'] as String?,
        currentCityId:    (j['current_city_id']    as num?)?.toInt(),
        currentStateId:   (j['current_state_id']   as num?)?.toInt(),
        currentCountryId: (j['current_country_id'] as num?)?.toInt(),
        currentPostalCode: j['current_postal_code'] as String?,
        permanentAddressLine1: j['permanent_address_line1'] as String?,
        permanentAddressLine2: j['permanent_address_line2'] as String?,
        permanentCityId:    (j['permanent_city_id']    as num?)?.toInt(),
        permanentStateId:   (j['permanent_state_id']   as num?)?.toInt(),
        permanentCountryId: (j['permanent_country_id'] as num?)?.toInt(),
        permanentPostalCode: j['permanent_postal_code'] as String?,
        emergencyContactName:     j['emergency_contact_name']     as String?,
        emergencyContactMobile:   j['emergency_contact_mobile']   as String?,
        emergencyContactRelation: j['emergency_contact_relation'] as String?,
        aadharNumber:        j['aadhar_number']        as String?,
        panNumber:           j['pan_number']           as String?,
        passportNumber:      j['passport_number']      as String?,
        bankAccountName:     j['bank_account_name']    as String?,
        bankName:            j['bank_name']            as String?,
        bankAccountNumber:   j['bank_account_number']  as String?,
        bankIfscCode:        j['bank_ifsc_code']       as String?,
        upiId:               j['upi_id']               as String?,
        profileImageUrl:     j['profile_image_url']    as String?,
        coverImageUrl:       j['cover_image_url']      as String?,
      );

  /// Convert to wire JSON. `null` values are kept so the server can clear
  /// columns deliberately — combine with PATCH-style updates by stripping
  /// `null`s in the caller if you only want to send changed fields.
  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (userId != null) 'user_id': userId,
        'display_name':              displayName,
        'headline':                  headline,
        'bio':                       bio,
        'slug':                      slug,
        'is_public':                 isPublic,
        'date_of_birth':             dateOfBirth,
        'gender':                    gender,
        'current_address_line1':     currentAddressLine1,
        'current_address_line2':     currentAddressLine2,
        'current_city_id':           currentCityId,
        'current_state_id':          currentStateId,
        'current_country_id':        currentCountryId,
        'current_postal_code':       currentPostalCode,
        'permanent_address_line1':   permanentAddressLine1,
        'permanent_address_line2':   permanentAddressLine2,
        'permanent_city_id':         permanentCityId,
        'permanent_state_id':        permanentStateId,
        'permanent_country_id':      permanentCountryId,
        'permanent_postal_code':     permanentPostalCode,
        'emergency_contact_name':    emergencyContactName,
        'emergency_contact_mobile':  emergencyContactMobile,
        'emergency_contact_relation':emergencyContactRelation,
        'aadhar_number':             aadharNumber,
        'pan_number':                panNumber,
        'passport_number':           passportNumber,
        'bank_account_name':         bankAccountName,
        'bank_name':                 bankName,
        'bank_account_number':       bankAccountNumber,
        'bank_ifsc_code':            bankIfscCode,
        'upi_id':                    upiId,
        'profile_image_url':         profileImageUrl,
        'cover_image_url':           coverImageUrl,
      };

  /// Strip nulls — useful when sending a PATCH-style partial update.
  Map<String, dynamic> toJsonNoNulls() {
    final map = toJson();
    map.removeWhere((_, v) => v == null);
    return map;
  }

  UserProfile copyWith(Map<String, Object?> overrides) {
    final m = toJson()..addAll(overrides);
    return UserProfile.fromJson(m);
  }

  @override
  List<Object?> get props => [
        id, userId, displayName, headline, bio, slug, isPublic, dateOfBirth, gender,
        currentAddressLine1, currentAddressLine2, currentCityId, currentStateId,
        currentCountryId, currentPostalCode,
        permanentAddressLine1, permanentAddressLine2, permanentCityId, permanentStateId,
        permanentCountryId, permanentPostalCode,
        emergencyContactName, emergencyContactMobile, emergencyContactRelation,
        aadharNumber, panNumber, passportNumber,
        bankAccountName, bankName, bankAccountNumber, bankIfscCode, upiId,
        profileImageUrl, coverImageUrl,
      ];
}
