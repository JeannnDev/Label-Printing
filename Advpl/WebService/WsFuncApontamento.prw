/**-------------------------------------------------------------------------------------------                                    **/
/** NOME DA FUNCAO : WsFuncApontamento                                                                                                      **/
/** DESCRICAO      : WebService para todas as Funções Apontamento                                                                 **/
/**-------------------------------------------------------------------------------------------                                    **/
/** Data        | Desenvolvedor         | Solicitacao        | Descricao                                                          **/
/**-------------------------------------------------------------------------------------------                                    **/
/** 22/04/2025  | Jean Correa da Silva  | -                  | GET para todas as Funções Apontamento                              **/
/**-------------------------------------------------------------------------------------------                                    **/

#Include "protheus.ch"
#Include "totvs.ch"
#Include "restful.ch"
#Include "rwmake.ch"
#Include "topconn.ch"

WSRESTFUL WsFuncApontamento DESCRIPTION "API REST para todas as Funções Apontamento."

    WSDATA FILIAL   AS STRING
    WSDATA OP       AS STRING
    WSDATA OPERADOR AS STRING
    WSDATA NF       AS STRING

    WSMETHOD GET DESCRIPTION "Consulta para todas as Funções Apontamento"  WSSYNTAX "/WsFuncApontamento/{OP}/{OPERADOR}"

    WSMETHOD POST DESCRIPTION "Atualiza a NF na OP na SC2" WSSYNTAX "/WsFuncApontamento/{OP}/{NF}"

END WSRESTFUL


WSMETHOD GET WSRECEIVE WSSERVICE WsFuncApontamento

    Local aArea            := GetArea()
    Local cOp              := ::OP
    Local cOperador        := ::OPERADOR
    Local n                := 0
    Local cOperacao        := ""
    Local aAux             := {}
    Local aTempArray       := {}
    Local oItem            := Nil
    Local aOps             := {}
    Local aApont           := {}
    Local x                := 0
    Private oResponse      := JsonObject():New()
    // Local cQry             := ""

    ::SetContentType("application/json")


    oResponse["op"]                  := ""
    oResponse["produto"]             := ""
    oResponse["descProduto"]         := ""
    oResponse["armazem"]             := ""
    oResponse["nf"]                 := ""
    oResponse["roteiroOp"]           := ""
    oResponse["roteiroUtilizado"]    := ""
    oResponse["nest"]                := 0
    oResponse["quantidadeSolicitada"] := 0
    oResponse["previsaoIni"]         := Nil
    oResponse["dtEntrega"]           := Nil
    oResponse["previsaoEntrega"]     := Nil
    oResponse["status"]              := ""
    oResponse["observacao"]          := ""
    oResponse["dtEmissao"]           := Nil
    oResponse["qtdProduzida"]        := 0
    oResponse["situacao"]            := ""
    oResponse["tipoOp"]              := ""
    oResponse["tpProducao"]          := ""
    oResponse["opTerceiro"]          := ""


    RpcClearEnv()
    RpcSetType(3)

    If RpcSetEnv("01", ::FILIAL)


        If Empty(cOp)
            oResponse := JsonObject():New()
            U_SetErro("Ordem de Produção não Informada.", 400)
            ::SetResponse(oResponse:toJson())
            RestArea(aArea)
            Return .F.
        EndIf

        If Empty(cOperador)
            oResponse := JsonObject():New()
            U_SetErro("Operador não Informado.", 400)
            ::SetResponse(oResponse:toJson())
            RestArea(aArea)
            Return .F.
        EndIf

        If !U_VldUser(cOperador)
            oResponse := JsonObject():New()
            U_SetErro("Usuário não cadastrado como operador.", 404)
            ::SetResponse(oResponse:toJson())
            RestArea(aArea)
            Return .F.
        EndIf

        If !U_QryTab(cOp)
            oResponse := JsonObject():New()
            U_SetErro("Ordem de Produção não encontrada ou inválida.", 404)
            ::SetResponse(oResponse:toJson())
            RestArea(aArea)
            Return .F.
        EndIf

        If Select("SOP") == 0 .Or. (SOP->(EoF()) .Or. Empty(SOP->PRODUTO))
            oResponse := JsonObject():New()
            U_SetErro("Nenhum dado encontrado para a OP informada.", 404)
            ::SetResponse(oResponse:toJson())
            RestArea(aArea)
            Return .F.
        EndIf

        SOP->(DbGoTop())


        aOps := U_ProdRotr(SOP->PRODUTO)["response"]

        aApont := U_ProdApto(SOP->OP)["response"]

        cRoteiroUtil := U_DecideRoteiro(SOP->PRODUTO)

        If Empty(cRoteiroUtil)
            oResponse := JsonObject():New()
            U_SetErro("Produto " + AllTrim(SOP->PRODUTO) + " sem roteiro 02.", 422)
            ::SetResponse(oResponse:toJson())
            RestArea(aArea)
            Return .F.
        EndIf

        aListaOper  := U_ObterListaOperacao(SOP->PRODUTO)["response"]


        aFinal := JsonObject():New()

        For n := 1 To Len(aListaOper)

            If  aListaOper[n]["codigo"] == cRoteiroUtil

                cOperacao := aListaOper[n]["operacao"]
                cRoteiro  := aListaOper[n]["codigo"]

                aAux := U_QProdOper(SOP->OP, SOP->PRODUTO, cOperacao)["response"]

                oOp := JsonObject():New()
                oOp["operac"]              := cOperacao
                oOp["recurso"]             := aOps[n]["recurso"]
                oOp["descricao"]           := aOps[n]["descricao"]
                oOp["recno"]               := aOps[n]["recno"]
                oOp["quantidadeProduzida"] := aAux["quantidade_produzida"]
                oOp["quantidadePerdida"]   := aAux["quantidade_perdida"]
                oOp["quantidadeFaltante"]  := aAux["quantidade_faltante"]
                oOp["parcialTotal"]        := aAux["pt"]
                oOp["status"]              := aAux["status"]


                aHist := {}
                For x := 1 To Len(aApont)
                    If aApont[x]["operac"] == cOperacao
                        oH := JsonObject():New()
                        oH["tempoApont"]    := aApont[x]["tempo de apont"]
                        oH["recurso"]       := aApont[x]["recurso"]
                        oH["qtdProd"]       := aApont[x]["qtd_prod"]
                        oH["qtdPerd"]       := aApont[x]["qtd_perd"]
                        oH["pt"]            := aApont[x]["pt"]
                        oH["hrIni"]         := aApont[x]["hrini"]
                        oH["dtIni"]         := aApont[x]["dtini"]
                        oH["dtFim"]         := aApont[x]["dtfim"]
                        oH["hrFim"]         := aApont[x]["hrfim"]
                        oH["operadorCod"]   := aApont[x]["operador_cod"]
                        oH["operadorNome"]  := aApont[x]["operador_nome"]
                        AAdd(aHist, oH)
                    EndIf
                Next

                oOp["historico"] := aHist

                If Type("aFinal[cRoteiro]") == "U"
                    aFinal[cRoteiro] := {}
                EndIf

                AAdd(aFinal[cRoteiro], oOp)

            EndIf

        Next

        // --- Resultado final ---
        oResponse["roteiro"] := aFinal


        // ---------------------------------------------------------
        // Obter os Saldos do Item
        // Descrição: Retorna os saldos do item por local de estoque
        // ---------------------------------------------------------

        aAux := U_SldItem(SOP->OP)["response"]

        aTempArray := {}

        For n := 1 To Len(aAux)
            oItem := JsonObject():New()
            oItem["produto"]   := aAux[n]["produto"]
            oItem["descricao"] := aAux[n]["descricao"]
            oItem["um"]        := aAux[n]["um"]
            oItem["qtOriginal"] := aAux[n]["qtOriginal"]
            oItem["qtdeEmp"]   := aAux[n]["qtde_emp"]
            oItem["saldoEstq"] := aAux[n]["saldo_estq"]
            oItem["armz"]      := aAux[n]["armz"]
            oItem["endereco"]  := aAux[n]["endereco"]
            oItem["status"]    := aAux[n]["status"]
            AAdd(aTempArray, oItem)
        Next

        If Len(aTempArray) == 0
            oMsg := JsonObject():New()
            oMsg["mensagem"] := FWHttpEncode("Nenhum saldo encontrado para a OP informada.")
            oMsg["success"]  := .F.
            AAdd(aTempArray, oMsg)
        EndIf

        oResponse["saldo_item"] := aTempArray
        // ---------------------------------------------------------

        oResponse["op"]                 := SOP->OP
        oResponse["produto"]            := AllTrim(SOP->PRODUTO)
        oResponse["descProduto"]        := AllTrim(SOP->DESCRI)
        oResponse["armazem"]            := SOP->ARMZ
        oResponse["nf"]                 := SOP->NF
        oResponse["roteiroOp"]          := SOP->ROTEIRO
        oResponse["roteiroUtilizado"]   := cRoteiroUtil
        // oResponse["nest"]               := SOP->NEST
        oResponse["quantidadeSolicitada"] := SOP->QUANT
        oResponse["previsaoIni"]        := SOP->DATPRI
        oResponse["dtEntrega"]          := SOP->DATRF
        oResponse["previsaoEntrega"]    := SOP->DATPRF
        oResponse["status"]             := AllTrim(SOP->STATUS_OP)
        oResponse["observacao"]         := AllTrim(SOP->OBS)
        oResponse["dtEmissao"]          := SOP->EMISSAO
        oResponse["qtdProduzida"]       := SOP->QUJE
        oResponse["situacao"]           := SOP->STATUS

    Else
        oResponse := JsonObject():New()
        oResponse["response"] := "Não foi possível conectar na empresa e filial informados."
        oResponse["status"]   := .F.
    EndIf

    ::SetResponse(oResponse:toJson())
    RestArea(aArea)
Return .T.


// ---------------------------------------------------------
// Metodo POST para receber o update da NF
// ---------------------------------------------------------
WSMETHOD POST WSRECEIVE WSSERVICE WsFuncApontamento
    Local aArea       := GetArea()
    Local cOp         := If(!Empty(::OP), ::OP, If(Len(::aURLParms) >= 1, ::aURLParms[1], ""))
    Local cNf         := If(!Empty(::NF), ::NF, If(Len(::aURLParms) >= 2, ::aURLParms[2], ""))
    Local cNum, cItem, cSequen
    Private oResponse := JsonObject():New()

    ::SetContentType("application/json")

    If Empty(cOp)
        oResponse["success"] := .F.
        oResponse["message"] := "Ordem de Producao (OP) nao informada."
        ::SetResponse(oResponse:toJson())
        RestArea(aArea)
        Return .F.
    EndIf

    If Empty(cNf)
        oResponse["success"] := .F.
        oResponse["message"] := "Nota Fiscal (NF) nao informada."
        ::SetResponse(oResponse:toJson())
        RestArea(aArea)
        Return .F.
    EndIf

    RpcClearEnv()
    RpcSetType(3)
    If RpcSetEnv("01", cFilial)
        DbSelectArea("SC2")
        SC2->(DbSetOrder(1)) // Filial + OP + Item + Seq

        cNum    := SubStr(cOp, 1, 6)
        cItem   := SubStr(cOp, 7, 2)
        cSequen := SubStr(cOp, 9, 3)

        If SC2->(DbSeek(xFilial("SC2") + cNum + cItem + cSequen))
            RecLock("SC2", .F.)
            SC2->C2_XNFISC := cNf
            SC2->(MsUnlock())

            oResponse["success"]      := .T.
            oResponse["message"]      := "NF atualizada com sucesso na OP."
            oResponse["rowsAffected"] := 1
        Else
            oResponse["success"] := .F.
            oResponse["message"] := "Ordem de Producao nao encontrada (SC2)."
        EndIf
    Else
        oResponse["success"] := .F.
        oResponse["message"] := "Nao foi possivel conectar na empresa/filial."
    EndIf

    ::SetResponse(oResponse:toJson())
    RestArea(aArea)
Return .T.
