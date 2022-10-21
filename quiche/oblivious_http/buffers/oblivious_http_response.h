#ifndef QUICHE_OBLIVIOUS_HTTP_BUFFERS_OBLIVIOUS_HTTP_RESPONSE_H_
#define QUICHE_OBLIVIOUS_HTTP_BUFFERS_OBLIVIOUS_HTTP_RESPONSE_H_

#include <stddef.h>

#include <string>

#include "absl/status/statusor.h"
#include "absl/strings/string_view.h"
#include "quiche/common/quiche_random.h"
#include "quiche/oblivious_http/buffers/oblivious_http_request.h"

namespace quiche {

class QUICHE_EXPORT ObliviousHttpResponse {
 public:
  // Parse and decrypt the OHttp response using ObliviousHttpContext context obj
  // that was returned from `CreateClientObliviousRequest` method. On success,
  // returns obj that callers will use to `GetDecryptedMessage`.
  // @params: Note that `oblivious_http_request_context` is required to stay
  // alive only for the lifetime of this factory method call.
  static absl::StatusOr<ObliviousHttpResponse> CreateClientObliviousResponse(
      absl::string_view encrypted_data,
      ObliviousHttpRequest::Context& oblivious_http_request_context);

  // Encrypt the input param `plaintext_payload` and create OHttp response using
  // ObliviousHttpContext context obj that was returned from
  // `CreateServerObliviousRequest` method. On success, returns obj that callers
  // will use to `Serialize` OHttp response. Generic Usecase : server-side calls
  // this method in the context of Response.
  // @params: Note that `oblivious_http_request_context` is required to stay
  // alive only for the lifetime of this factory method call.
  // @params: If callers do not provide `quiche_random`, it will be initialized
  // to default supplied `QuicheRandom::GetInstance()`. It's recommended that
  // callers initialize `QuicheRandom* quiche_random` as a Singleton instance
  // within their code and pass in the same, in order to have optimized random
  // string generation. `quiche_random` is required to stay alive only for the
  // lifetime of this factory method call.
  static absl::StatusOr<ObliviousHttpResponse> CreateServerObliviousResponse(
      absl::string_view plaintext_payload,
      ObliviousHttpRequest::Context& oblivious_http_request_context,
      QuicheRandom* quiche_random = nullptr);

  // Copyable.
  ObliviousHttpResponse(const ObliviousHttpResponse& other) = default;
  ObliviousHttpResponse& operator=(const ObliviousHttpResponse& other) =
      default;

  // Movable.
  ObliviousHttpResponse(ObliviousHttpResponse&& other) = default;
  ObliviousHttpResponse& operator=(ObliviousHttpResponse&& other) = default;

  ~ObliviousHttpResponse() = default;

  // Generic Usecase : server-side calls this method in the context of Response
  // to serialize OHTTP response that will be returned to client-side.
  // Returns serialized OHTTP response bytestring.
  std::string EncapsulateAndSerialize() const;

  absl::string_view GetPlaintextData() const;

 private:
  struct CommonAeadParamsResult {
    const EVP_AEAD* evp_hpke_aead;
    const size_t aead_key_len;
    const size_t aead_nonce_len;
    const size_t secret_len;
  };

  struct CommonOperationsResult {
    bssl::UniquePtr<EVP_AEAD_CTX> aead_ctx;
    const std::string aead_nonce;
  };

  explicit ObliviousHttpResponse(std::string resp_nonce,
                                 std::string resp_ciphertext,
                                 std::string resp_plaintext);

  // Determines AEAD key len(Nk), AEAD nonce len(Nn) based on HPKE context and
  // further estimates secret_len = std::max(Nk, Nn)
  static absl::StatusOr<CommonAeadParamsResult> GetCommonAeadParams(
      ObliviousHttpRequest::Context& oblivious_http_request_context);
  // Performs operations related to response handling that are common between
  // client and server.
  static absl::StatusOr<CommonOperationsResult> CommonOperationsToEncapDecap(
      absl::string_view response_nonce,
      ObliviousHttpRequest::Context& oblivious_http_request_context,
      const size_t aead_key_len, const size_t aead_nonce_len,
      const size_t secret_len);
  std::string response_nonce_;
  std::string response_ciphertext_;
  std::string response_plaintext_;
};

}  // namespace quiche

#endif  // QUICHE_OBLIVIOUS_HTTP_BUFFERS_OBLIVIOUS_HTTP_RESPONSE_H_
